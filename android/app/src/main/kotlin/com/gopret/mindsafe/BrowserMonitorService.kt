package com.gopret.mindsafe

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.EventChannel

class BrowserMonitorService : AccessibilityService() {
    private val TAG = "BrowserMonitor"

    // Debounce state: only commit a URL after 500ms with no new URL event
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingRunnable: Runnable? = null
    private var pendingUrl: String = ""          // URL currently waiting to be committed
    private var lastCommittedUrl: String = ""

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
            // Listen to BOTH event types:
            // - TYPE_WINDOW_STATE_CHANGED: fires on navigation AND omnibox open/close
            // - TYPE_WINDOW_CONTENT_CHANGED: fires while typing (used to CANCEL pending)
            // We decide what to do based on url_bar.isFocused at the time of the event.
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
            packageNames = BROWSER_URL_BARS.keys.toTypedArray()
        }
        serviceInfo = info

        Log.i(TAG, "BrowserMonitorService connected, monitoring ${BROWSER_URL_BARS.size} browsers")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        val urlBarIds = BROWSER_URL_BARS[packageName] ?: return

        try {
            val rootNode = rootInActiveWindow ?: return

            for (urlBarId in urlBarIds) {
                val urlNodes = rootNode.findAccessibilityNodeInfosByViewId(urlBarId)
                if (urlNodes != null && urlNodes.isNotEmpty()) {
                    val urlNode = urlNodes[0]

                    if (urlNode.isFocused) {
                        // Address bar is being edited → user is typing.
                        // Cancel any pending commit so we don't record an unvisited URL.
                        pendingRunnable?.let { mainHandler.removeCallbacks(it) }
                        pendingRunnable = null
                    } else {
                        // Address bar not focused → page has loaded and URL is stable.
                        val urlText = urlNode.text?.toString()
                        if (!urlText.isNullOrBlank()) {
                            scheduleUrlCapture(urlText, packageName)
                        }
                    }
                    break
                }
            }

            rootNode.recycle()
        } catch (e: Exception) {
            Log.w(TAG, "Error reading URL: ${e.message}")
        }
    }

    /**
     * Schedule a URL commit after 500ms of stability.
     * CRITICAL: if the same URL is already pending, do NOT reset the timer.
     * This prevents page-load events (images, JS, etc.) from continuously
     * resetting the debounce, which would delay or prevent commit entirely.
     * Only cancel and reschedule if a DIFFERENT URL arrives (e.g. redirect).
     */
    private fun scheduleUrlCapture(rawUrl: String, packageName: String) {
        // Normalise URL
        var url = rawUrl.trim()
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://$url"
        }

        // Quick host validation - reject clearly invalid input immediately
        val host = try { java.net.URI(url).host ?: "" } catch (_: Exception) { "" }
        if (host.isEmpty() || !host.contains('.')) return
        if (host.substringAfterLast('.').length < 2) return

        // If the same URL is already pending, leave the timer as-is
        // (prevents reset-storm from repeated events during page loading)
        if (url == pendingUrl && pendingRunnable != null) return

        // Different URL → cancel previous and schedule new
        pendingRunnable?.let { mainHandler.removeCallbacks(it) }
        pendingUrl = url

        val capturedUrl = url
        val capturedHost = host
        val capturedPackage = packageName

        val runnable = Runnable {
            pendingUrl = ""
            commitUrl(capturedUrl, capturedHost, capturedPackage)
        }
        pendingRunnable = runnable
        mainHandler.postDelayed(runnable, 500L)
    }

    /** Commit a URL that has been stable for 1.5 seconds. */
    private fun commitUrl(url: String, host: String, packageName: String) {
        // Skip if same as last committed URL (no change after debounce)
        if (url == lastCommittedUrl) return
        lastCommittedUrl = url

        val now = System.currentTimeMillis()
        Log.d(TAG, "URL committed [$packageName]: $url (host: $host)")

        // Write to SharedPreferences for consume-on-resume
        try {
            val prefs = applicationContext.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val key = "flutter.pending_url_$now"
            prefs.edit().putString(key, "$url|$packageName|$now").apply()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to write pending URL to SharedPreferences", e)
        }

        // Send to main Flutter engine if connected (real-time UI update)
        try {
            eventSink?.success(mapOf(
                "type" to "url",
                "url" to url,
                "package" to packageName,
                "timestamp" to now
            ))
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send URL event", e)
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "BrowserMonitorService interrupted")
    }

    override fun onDestroy() {
        pendingRunnable?.let { mainHandler.removeCallbacks(it) }
        super.onDestroy()
        isRunning = false
        Log.i(TAG, "BrowserMonitorService destroyed")
    }
}

