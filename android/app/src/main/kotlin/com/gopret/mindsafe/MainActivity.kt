package com.gopret.mindsafe

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.net.VpnService
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val VPN_CHANNEL = "com.mindsafe/vpn"
    private val VPN_EVENTS = "com.mindsafe/vpn_events"
    private val URL_EVENTS = "com.mindsafe/url_events"
    private val VPN_REQUEST_CODE = 1001
    
    private var methodResult: MethodChannel.Result? = null
    private var pendingAllowedPackages: ArrayList<String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method Channel for VPN + Accessibility control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startVpn" -> {
                        methodResult = result
                        @Suppress("UNCHECKED_CAST")
                        pendingAllowedPackages = call.argument<ArrayList<String>>("allowedPackages")
                        startVpn()
                    }
                    "getBrowserApps" -> result.success(getBrowserApps())
                    "stopVpn" -> {
                        stopVpn()
                        result.success(true)
                    }
                    "getStatus" -> result.success(getVpnStatus())
                    "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Event Channel for VPN domain events (DNS monitoring)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    LocalVpnService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    LocalVpnService.eventSink = null
                }
            })
        
        // Event Channel for browser URL events (AccessibilityService)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, URL_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BrowserMonitorService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    BrowserMonitorService.eventSink = null
                }
            })
    }

    private fun startVpn() {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            startActivityForResult(intent, VPN_REQUEST_CODE)
        } else {
            onActivityResult(VPN_REQUEST_CODE, Activity.RESULT_OK, null)
        }
    }

    private fun getBrowserApps(): List<Map<String, Any>> {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
        intent.addCategory(Intent.CATEGORY_BROWSABLE)
        val resolveInfos = packageManager.queryIntentActivities(intent, PackageManager.MATCH_ALL)

        val seen = mutableSetOf<String>()
        val result = mutableListOf<Map<String, Any>>()

        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            if (pkg == packageName || !seen.add(pkg)) continue

            val appName = info.loadLabel(packageManager).toString()
            val iconBytes = try {
                val drawable = info.loadIcon(packageManager)
                val bitmap = if (drawable is BitmapDrawable) {
                    drawable.bitmap
                } else {
                    val bmp = Bitmap.createBitmap(48, 48, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, 48, 48)
                    drawable.draw(canvas)
                    bmp
                }
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            } catch (e: Exception) {
                ByteArray(0)
            }

            result.add(mapOf(
                "packageName" to pkg,
                "appName" to appName,
                "icon" to iconBytes
            ))
        }

        return result
    }

    private fun stopVpn() {
        val intent = Intent(this, LocalVpnService::class.java)
        intent.action = LocalVpnService.ACTION_STOP
        startService(intent)
    }

    private fun getVpnStatus(): String {
        return if (LocalVpnService.isRunning) "running" else "stopped"
    }

    private fun isAccessibilityEnabled(): Boolean {
        val serviceName = "${packageName}/${BrowserMonitorService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.split(':').any { it.equals(serviceName, ignoreCase = true) }
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                val intent = Intent(this, LocalVpnService::class.java)
                intent.action = LocalVpnService.ACTION_START
                pendingAllowedPackages?.let {
                    intent.putStringArrayListExtra("allowedPackages", it)
                }
                startService(intent)
                pendingAllowedPackages = null
                methodResult?.success(true)
            } else {
                methodResult?.error("PERMISSION_DENIED", "VPN permission denied", null)
            }
            methodResult = null
        }
    }
}
