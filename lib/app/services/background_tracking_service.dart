import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key prefix used by BrowserMonitorService.kt when saving pending URL events.
/// Kotlin writes keys as `flutter.pending_url_<timestamp>`.
/// Dart SharedPreferences strips "flutter." so we search for "pending_url_".
const _pendingUrlPrefix = 'pending_url_';

/// Key for storing the current userId so Kotlin-side can access it.
const _userIdPrefKey = 'bg_current_user_id';

/// Persist the current userId so it can be read later when consuming sessions.
Future<void> setBackgroundUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_userIdPrefKey, userId);
}

/// Read all pending URL events that BrowserMonitorService.kt wrote to
/// SharedPreferences while the app was closed. Returns them as a list of
/// maps with keys: url, package, timestamp. Clears the queue after reading.
Future<List<Map<String, dynamic>>> consumePendingUrls() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // force re-read from disk

  final keys =
      prefs.getKeys().where((k) => k.startsWith(_pendingUrlPrefix)).toList()
        ..sort(); // process in chronological order

  if (keys.isEmpty) return [];

  final results = <Map<String, dynamic>>[];

  for (final key in keys) {
    final raw = prefs.getString(key);
    if (raw == null) continue;

    // Format: "<url>|<packageName>|<timestamp>"
    final parts = raw.split('|');
    if (parts.length >= 3) {
      results.add({
        'url': parts[0],
        'package': parts[1],
        'timestamp': int.tryParse(parts[2]) ?? 0,
      });
    }
    await prefs.remove(key);
  }

  debugPrint('🔄 Consumed ${results.length} pending URLs from background');
  return results;
}

/// Stub - no longer needed, but kept for API compatibility.
Future<void> initBackgroundService() async {
  // No-op: background tracking is now handled natively by
  // BrowserMonitorService.kt + consume-on-resume in VpnController.
}
