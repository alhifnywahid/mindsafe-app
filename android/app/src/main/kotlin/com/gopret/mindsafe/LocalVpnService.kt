package com.gopret.mindsafe

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import kotlin.concurrent.thread

class LocalVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val CHANNEL_ID = "mindsafe_vpn_channel"
    private val NOTIFICATION_ID = 1
    private val TAG = "MindsafeVPN"

    // Local DNS address within VPN subnet - NOT an external IP
    // This prevents Android from trying DNS-over-TLS (DoT) on it
    private val LOCAL_DNS_IP = "10.0.0.1"
    private val REAL_DNS_IP = "8.8.8.8"
    
    companion object {
        var eventSink: EventChannel.EventSink? = null
        var isRunning = false
        const val ACTION_START = "com.gopret.mindsafe.START_VPN"
        const val ACTION_STOP = "com.gopret.mindsafe.STOP_VPN"
    }

    private var allowedPackages: List<String> = emptyList()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                allowedPackages = intent.getStringArrayListExtra("allowedPackages") ?: emptyList()
                startVpn()
            }
            ACTION_STOP -> stopVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (isRunning) return
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification("Mindsafe Active", "Monitoring DNS queries"))
        
        try {
            // VPN address is 10.0.0.2, DNS server is 10.0.0.1 (local)
            // Only route the VPN subnet - no external IPs routed through VPN
            // This way ALL non-DNS traffic goes directly to the internet
            val builder = Builder()
                .addAddress("10.0.0.2", 24)          // VPN interface on 10.0.0.x subnet
                .addRoute("10.0.0.0", 24)             // Only route VPN subnet through tunnel
                .addDnsServer(LOCAL_DNS_IP)             // DNS -> local VPN address (no DoT attempt)
                .setSession("Mindsafe VPN")
                .setMtu(1500)

            // Exclude our own app to prevent infinite loop
            try {
                builder.addDisallowedApplication(packageName)
            } catch (e: Exception) {
                Log.w(TAG, "Could not exclude own package: ${e.message}")
            }

            // Filter VPN to only selected browser apps
            if (allowedPackages.isNotEmpty()) {
                // When using addAllowedApplication, only those apps' traffic goes through VPN
                // Note: addAllowedApplication and addDisallowedApplication are mutually exclusive
                // So we rebuild without the disallowed and use only allowed
                val filteredBuilder = Builder()
                    .addAddress("10.0.0.2", 24)
                    .addRoute("10.0.0.0", 24)
                    .addDnsServer(LOCAL_DNS_IP)
                    .setSession("Mindsafe VPN")
                    .setMtu(1500)

                for (pkg in allowedPackages) {
                    try {
                        filteredBuilder.addAllowedApplication(pkg)
                        Log.d(TAG, "Allowed app: $pkg")
                    } catch (e: Exception) {
                        Log.w(TAG, "Could not allow package $pkg: ${e.message}")
                    }
                }

                vpnInterface = filteredBuilder.establish()
            } else {
                vpnInterface = builder.establish()
            }
            isRunning = true
            
            Log.i(TAG, "VPN started. DNS queries will be intercepted via $LOCAL_DNS_IP")
            
            sendEventToFlutter(mapOf("type" to "status", "status" to "running"))
            
            thread(name = "VPN-DNS-Proxy") {
                runDnsProxy()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN", e)
            sendEventToFlutter(mapOf("type" to "error", "message" to "Start failed: ${e.message}"))
            stopSelf()
        }
    }

    private fun stopVpn() {
        isRunning = false
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        sendEventToFlutter(mapOf("type" to "status", "status" to "stopped"))
        stopForeground(true)
        stopSelf()
    }

    /**
     * Reads DNS packets from VPN tunnel, forwards to real DNS (8.8.8.8),
     * and writes responses back. Acts as a transparent DNS proxy.
     */
    private fun runDnsProxy() {
        val fd = vpnInterface?.fileDescriptor ?: return
        val input = FileInputStream(fd)
        val output = FileOutputStream(fd)
        val packetBuf = ByteArray(32767)
        
        Log.i(TAG, "DNS proxy loop started")
        
        try {
            while (isRunning) {
                val len = input.read(packetBuf)
                if (len <= 0) {
                    Thread.sleep(10)
                    continue
                }
                
                try {
                    processDnsPacket(packetBuf, len, output)
                } catch (e: Exception) {
                    Log.w(TAG, "Packet error: ${e.message}")
                }
            }
        } catch (e: Exception) {
            if (isRunning) Log.e(TAG, "DNS proxy loop crashed", e)
        }
        
        Log.i(TAG, "DNS proxy loop ended")
    }

    private fun processDnsPacket(packet: ByteArray, length: Int, output: FileOutputStream) {
        if (length < 28) return // Min: 20 IP + 8 UDP
        
        // Verify IPv4
        if ((packet[0].toInt() shr 4 and 0x0F) != 4) return
        
        val ihl = (packet[0].toInt() and 0x0F) * 4
        val protocol = packet[9].toInt() and 0xFF
        
        // Only UDP (17)
        if (protocol != 17) return
        if (length < ihl + 8) return
        
        val dstPort = ((packet[ihl + 2].toInt() and 0xFF) shl 8) or
                      (packet[ihl + 3].toInt() and 0xFF)
        
        // Only DNS (port 53)
        if (dstPort != 53) return
        
        // Save original packet info for building response
        val srcIp = packet.copyOfRange(12, 16)       // 10.0.0.2 (our VPN addr)
        val dstIp = packet.copyOfRange(16, 20)       // 10.0.0.1 (local DNS)
        val srcPort = ((packet[ihl].toInt() and 0xFF) shl 8) or
                      (packet[ihl + 1].toInt() and 0xFF)
        
        // Extract DNS payload
        val dnsStart = ihl + 8
        val dnsLen = length - dnsStart
        if (dnsLen < 12) return
        
        val dnsPayload = packet.copyOfRange(dnsStart, length)
        
        // Parse domain name from query (but don't send event yet)
        val domain = parseDnsName(dnsPayload)
        
        // Forward to real DNS server
        var socket: DatagramSocket? = null
        try {
            socket = DatagramSocket()
            protect(socket)  // CRITICAL: bypass VPN to avoid infinite loop
            socket.soTimeout = 5000
            
            // Send to real DNS
            val realDns = InetAddress.getByName(REAL_DNS_IP)
            socket.send(DatagramPacket(dnsPayload, dnsPayload.size, realDns, 53))
            
            // Receive response
            val recvBuf = ByteArray(4096)
            val recvPkt = DatagramPacket(recvBuf, recvBuf.size)
            socket.receive(recvPkt)
            
            val dnsResponse = recvBuf.copyOf(recvPkt.length)
            
            // Only send domain event if DNS response is NOERROR (RCODE=0)
            // This filters out NXDOMAIN, SERVFAIL, etc. (phantom domains)
            if (domain != null && dnsResponse.size >= 4) {
                val rcode = dnsResponse[3].toInt() and 0x0F
                if (rcode == 0) {
                    sendDomainEvent(domain)
                } else {
                    Log.d(TAG, "Skipped domain $domain (RCODE=$rcode)")
                }
            }
            
            // Build IP+UDP response and write back to VPN tunnel
            // Source: dstIp (10.0.0.1 = DNS server) -> Dest: srcIp (10.0.0.2 = client)
            val responsePacket = buildIpUdpPacket(
                srcIp = dstIp,           // response FROM dns server
                dstIp = srcIp,           // response TO client
                srcPort = 53,
                dstPort = srcPort,
                payload = dnsResponse
            )
            
            synchronized(output) {
                output.write(responsePacket)
                output.flush()
            }
            
        } catch (e: Exception) {
            Log.w(TAG, "DNS forward error for $domain: ${e.message}")
        } finally {
            try { socket?.close() } catch (_: Exception) {}
        }
    }

    /**
     * Constructs a valid IPv4 + UDP packet with correct checksums.
     */
    private fun buildIpUdpPacket(
        srcIp: ByteArray,
        dstIp: ByteArray,
        srcPort: Int,
        dstPort: Int,
        payload: ByteArray
    ): ByteArray {
        val ipHdrLen = 20
        val udpHdrLen = 8
        val totalLen = ipHdrLen + udpHdrLen + payload.size
        val pkt = ByteArray(totalLen)
        
        // --- IP Header ---
        pkt[0] = 0x45.toByte()                                     // v4, IHL=5
        pkt[1] = 0                                                  // TOS
        pkt[2] = (totalLen shr 8).toByte()                          // Total length
        pkt[3] = (totalLen and 0xFF).toByte()
        // bytes 4-5: identification = 0
        pkt[6] = 0x40.toByte()                                     // Don't Fragment
        pkt[7] = 0                                                  // Fragment offset
        pkt[8] = 64                                                 // TTL
        pkt[9] = 17                                                 // UDP
        // bytes 10-11: checksum = 0 (computed below)
        System.arraycopy(srcIp, 0, pkt, 12, 4)                     // Src IP
        System.arraycopy(dstIp, 0, pkt, 16, 4)                     // Dst IP
        
        // IP checksum
        var cksum: Long = 0
        for (i in 0 until ipHdrLen step 2) {
            cksum += ((pkt[i].toInt() and 0xFF) shl 8 or (pkt[i + 1].toInt() and 0xFF)).toLong()
        }
        while (cksum shr 16 != 0L) cksum = (cksum and 0xFFFF) + (cksum shr 16)
        val ipCk = cksum.inv().toInt() and 0xFFFF
        pkt[10] = (ipCk shr 8).toByte()
        pkt[11] = (ipCk and 0xFF).toByte()
        
        // --- UDP Header ---
        pkt[ipHdrLen]     = (srcPort shr 8).toByte()
        pkt[ipHdrLen + 1] = (srcPort and 0xFF).toByte()
        pkt[ipHdrLen + 2] = (dstPort shr 8).toByte()
        pkt[ipHdrLen + 3] = (dstPort and 0xFF).toByte()
        val udpLen = udpHdrLen + payload.size
        pkt[ipHdrLen + 4] = (udpLen shr 8).toByte()
        pkt[ipHdrLen + 5] = (udpLen and 0xFF).toByte()
        // bytes 6-7: UDP checksum = 0 (optional for IPv4)
        
        // --- Payload ---
        System.arraycopy(payload, 0, pkt, ipHdrLen + udpHdrLen, payload.size)
        
        return pkt
    }

    private fun parseDnsName(dns: ByteArray): String? {
        try {
            if (dns.size < 13) return null
            var pos = 12
            val sb = StringBuilder()
            
            var labelLen = dns[pos].toInt() and 0xFF
            pos++
            
            while (labelLen in 1..63 && pos + labelLen <= dns.size) {
                if (sb.isNotEmpty()) sb.append('.')
                for (i in 0 until labelLen) {
                    sb.append(dns[pos + i].toInt().toChar())
                }
                pos += labelLen
                if (pos >= dns.size) break
                labelLen = dns[pos].toInt() and 0xFF
                pos++
            }
            
            return if (sb.isNotEmpty()) sb.toString() else null
        } catch (_: Exception) {
            return null
        }
    }

    private fun sendDomainEvent(domain: String) {
        Log.d(TAG, "Domain: $domain")
        sendEventToFlutter(mapOf(
            "type" to "domain",
            "domain" to domain,
            "timestamp" to System.currentTimeMillis()
        ))
    }

    private fun sendEventToFlutter(event: Map<String, Any>) {
        try {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                eventSink?.success(event)
            }
        } catch (_: Exception) {}
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "VPN Service", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Mindsafe VPN monitoring"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun createNotification(title: String, content: String): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title).setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent).setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW).build()
    }

    override fun onDestroy() { super.onDestroy(); stopVpn() }
    override fun onRevoke() {
        super.onRevoke()
        sendEventToFlutter(mapOf("type" to "status", "status" to "revoked"))
        stopVpn()
    }
}
