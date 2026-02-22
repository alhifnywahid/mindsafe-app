import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Service that manages local notifications for MindSafe.
/// Currently used to alert users when an unsafe domain is detected.
class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Per-domain cooldown so we don't spam the user.
  /// Key = domain, Value = last notification time.
  final Map<String, DateTime> _cooldowns = {};

  /// Minimum gap between notifications for the same domain.
  static const _cooldownDuration = Duration(seconds: 30);

  /// Notification channel details (Android).
  static const _channelId = 'mindsafe_alerts';
  static const _channelName = 'MindSafe Alerts';
  static const _channelDescription =
      'Alerts when an unsafe website is detected';

  /// Human-readable labels for each threat category.
  static const _categoryLabels = <String, String>{
    'adult': 'Konten Dewasa',
    'gambling': 'Judi Online',
    'phishing': 'Phishing',
    'malware': 'Malware',
    'cryptojacking': 'Cryptojacking',
    'drugs': 'Narkoba',
    'hacking': 'Hacking',
    'dangerous': 'Berbahaya',
    'dating': 'Dating',
    'ddos': 'DDoS',
    'warez': 'Warez / Bajakan',
  };

  Future<NotificationService> init() async {
    // Android init settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS / macOS init settings (optional, no-op on Android)
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Create notification channel (doesn't require permission)
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }

    debugPrint(
      '✅ NotificationService initialized (permission not yet requested)',
    );
    return this;
  }

  /// Check if OS-level notification permission is granted.
  Future<bool> areNotificationsAllowed() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true; // Non-Android platforms — assume allowed
  }

  /// Request notification permission from the OS.
  /// Returns true if granted, false if denied.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('🔔 Notification permission granted: $granted');
      return granted ?? false;
    }
    return true;
  }

  /// Show a notification when an unsafe domain is detected.
  ///
  /// Respects a per-domain cooldown of [_cooldownDuration] to avoid spam.
  Future<void> showUnsafeDomainNotification(
    String domain,
    String category,
  ) async {
    // Check cooldown
    final now = DateTime.now();
    final lastShown = _cooldowns[domain];
    if (lastShown != null && now.difference(lastShown) < _cooldownDuration) {
      debugPrint('🔔 Notification skipped (cooldown): $domain');
      return; // Still in cooldown — skip
    }
    _cooldowns[domain] = now;

    final label = _categoryLabels[category] ?? category;

    // Use the domain's hashCode as the notification ID so each domain
    // gets its own slot (subsequent notifications for the same domain
    // replace the previous one).
    final notificationId = domain.hashCode.abs() % 100000;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Unsafe domain detected',
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Domain "$domain" terdeteksi sebagai $label.\n'
        'Tetap waspada dan jaga keamanan browsing kamu! 🛡️',
        contentTitle: '⚠️ Website Tidak Aman Terdeteksi',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        notificationId,
        '⚠️ Website Tidak Aman Terdeteksi',
        '"$domain" dikategorikan sebagai $label',
        details,
      );
      debugPrint(
        '🔔 Notification shown: $domain → $label (id=$notificationId)',
      );
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  /// Clean up old cooldown entries to prevent memory leaks.
  /// Call periodically if needed.
  void cleanupCooldowns() {
    final now = DateTime.now();
    _cooldowns.removeWhere(
      (_, time) => now.difference(time) > const Duration(minutes: 5),
    );
  }
}
