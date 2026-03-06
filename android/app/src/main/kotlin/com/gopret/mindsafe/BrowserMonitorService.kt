package com.gopret.mindsafe

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.EventChannel

class BrowserMonitorService : AccessibilityService() {
    private val TAG = "BrowserMonitor"
    private var lastUrl: String = ""
    private var lastUrlTime: Long = 0

    companion object {
        var eventSink: EventChannel.EventSink? = null
        var isRunning = false

        // Browser packages and their URL bar view IDs
        val BROWSER_URL_BARS = mapOf(
            // Chrome & Chromium-based
            "com.android.chrome" to listOf("com.android.chrome:id/url_bar", "com.android.chrome:id/search_box_text"),
            "com.chrome.beta" to listOf("com.chrome.beta:id/url_bar", "com.chrome.beta:id/search_box_text"),
            "com.chrome.dev" to listOf("com.chrome.dev:id/url_bar"),
            
            // Brave
            "com.brave.browser" to listOf("com.brave.browser:id/url_bar"),
            "com.brave.browser_beta" to listOf("com.brave.browser_beta:id/url_bar"),
            
            // Edge
            "com.microsoft.emmx" to listOf("com.microsoft.emmx:id/url_bar", "com.microsoft.emmx:id/url_bar_title"),
            
            // Samsung Internet
            "com.sec.android.app.sbrowser" to listOf(
                "com.sec.android.app.sbrowser:id/location_bar_edit_text",
                "com.sec.android.app.sbrowser:id/address_bar_edit_text",
                "com.sec.android.app.sbrowser:id/location_bar_text"
            ),
            "com.sec.android.app.sbrowser.beta" to listOf(
                "com.sec.android.app.sbrowser.beta:id/location_bar_edit_text"
            ),
            
            // Firefox
            "org.mozilla.firefox" to listOf(
                "org.mozilla.firefox:id/mozac_browser_toolbar_url_view",
                "org.mozilla.firefox:id/url_bar_title"
            ),
            "org.mozilla.firefox_beta" to listOf("org.mozilla.firefox_beta:id/mozac_browser_toolbar_url_view"),
            "org.mozilla.fenix" to listOf("org.mozilla.fenix:id/mozac_browser_toolbar_url_view"),
            
            // Opera
            "com.opera.browser" to listOf("com.opera.browser:id/url_field"),
            "com.opera.mini.native" to listOf("com.opera.mini.native:id/url_field"),
            
            // Vivaldi
            "com.vivaldi.browser" to listOf("com.vivaldi.browser:id/url_bar"),
            
            // DuckDuckGo
            "com.duckduckgo.mobile.android" to listOf("com.duckduckgo.mobile.android:id/omnibarTextInput"),
            
            // UC Browser
            "com.UCMobile.intl" to listOf("com.UCMobile.intl:id/address_editor_with_progress")
        )
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 300
            // Monitor all browser packages
            packageNames = BROWSER_URL_BARS.keys.toTypedArray()
        }
        serviceInfo = info
        
        Log.i(TAG, "BrowserMonitorService connected, monitoring ${BROWSER_URL_BARS.size} browsers")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val packageName = event.packageName?.toString() ?: return
        
        // Check if it's a monitored browser
        val urlBarIds = BROWSER_URL_BARS[packageName] ?: return
        
        try {
            val rootNode = rootInActiveWindow ?: return
            
            // Try each known URL bar ID for this browser
            for (urlBarId in urlBarIds) {
                val urlNodes = rootNode.findAccessibilityNodeInfosByViewId(urlBarId)
                if (urlNodes != null && urlNodes.isNotEmpty()) {
                    val urlText = urlNodes[0].text?.toString()
                    if (!urlText.isNullOrBlank()) {
                        processUrl(urlText, packageName)
                        break
                    }
                }
            }
            
            rootNode.recycle()
        } catch (e: Exception) {
            Log.w(TAG, "Error reading URL: ${e.message}")
        }
    }

    private fun processUrl(rawUrl: String, packageName: String) {
        // Normalize the URL
        var url = rawUrl.trim()
        
        // Some browsers show just domain, some show full URL
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://$url"
        }
        
        // Deduplicate: don't send same URL within 1 second
        val now = System.currentTimeMillis()
        if (url == lastUrl && now - lastUrlTime < 1000) return
        
        lastUrl = url
        lastUrlTime = now
        
        Log.d(TAG, "URL captured [$packageName]: $url")
        
        // Send to Flutter
        val event = mapOf(
            "type" to "url",
            "url" to url,
            "package" to packageName,
            "timestamp" to now
        )
        
        try {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                eventSink?.success(event)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send URL event", e)
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "BrowserMonitorService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        Log.i(TAG, "BrowserMonitorService destroyed")
    }
}
