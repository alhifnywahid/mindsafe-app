import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsafe_flutter/data/services/vpn_service.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/domain_classifier.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';
import 'package:mindsafe_flutter/data/services/notification_service.dart';

class VpnController extends GetxController with WidgetsBindingObserver {
  final VpnService _vpnService = Get.find<VpnService>();
  final LocalDatabase _db = Get.find<LocalDatabase>();
  final AuthService _authService = Get.find<AuthService>();
  final DomainClassifier _classifier = Get.find<DomainClassifier>();

  final isRunning = false.obs;
  final isAccessibilityEnabled = false.obs;
  final todayDomainCount = 0.obs;
  final todayDurationMinutes = 0.obs;
  final todayUrlCount = 0.obs;

  // Monitoring scope
  final trackAllApps = false.obs;
  static const _prefKeyTrackAll = 'track_all_apps';

  // Notification toggle
  final isNotificationEnabled = false.obs;
  static const _prefKeyNotification = 'notification_enabled';

  // Weekly stats
  final weeklyTotalMinutes = 0.obs;
  final weeklyDailyCounts = <int>[0, 0, 0, 0, 0, 0, 0].obs; // last 7 days
  final yesterdayDomainCount = 0.obs;
  final yesterdayDurationMinutes = 0.obs;

  // Top domains & category breakdown
  final todayTopDomains = <MapEntry<String, int>>[].obs;
  final todayCategoryBreakdown = <MapEntry<String, int>>[].obs;

  final _domainLastSeen = <String, DateTime>{};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _syncVpnStatus();
    _loadTrackAllApps();
    _loadNotificationPref();
    _listenToVpnEvents();
    _listenToUrlEvents();
    _calculateTodayStats();
    _calculateWeeklyStats();
    _checkAccessibility();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check accessibility when user returns to the app
      // (e.g. after enabling it in device settings)
      _checkAccessibility();
    }
  }

  /// Load trackAllApps preference from SharedPreferences
  Future<void> _loadTrackAllApps() async {
    final prefs = await SharedPreferences.getInstance();
    trackAllApps.value = prefs.getBool(_prefKeyTrackAll) ?? false;
  }

  /// Load notification preference from SharedPreferences
  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    isNotificationEnabled.value = prefs.getBool(_prefKeyNotification) ?? false;
  }

  /// Toggle notification on/off.
  Future<void> setNotificationEnabled(bool value) async {
    isNotificationEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotification, value);
  }

  /// Toggle monitoring scope: all apps vs browsers only.
  /// If VPN is running, restarts it with the updated scope.
  Future<void> setTrackAllApps(bool value) async {
    trackAllApps.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyTrackAll, value);

    // Restart VPN if currently running so the change takes effect immediately
    final wasRunning = isRunning.value;
    if (wasRunning) {
      await _vpnService.stopVpn();
      // Give the native VPN time to fully release resources
      await Future.delayed(const Duration(milliseconds: 500));
      final packages = value ? null : await _getBrowserPackages();
      final success = await _vpnService.startVpn(allowedPackages: packages);
      if (success) {
        isRunning.value = true;
      }
    }
  }

  /// Fetch browser package names from native side
  Future<List<String>?> _getBrowserPackages() async {
    final apps = await _vpnService.getBrowserApps();
    if (apps.isEmpty) return null;
    return apps.map((a) => a.packageName).toList();
  }

  /// Query the native side for the actual VPN status so the UI
  /// reflects the correct state after an app restart.
  Future<void> _syncVpnStatus() async {
    final status = await _vpnService.getStatus();
    isRunning.value = (status == 'running');
  }

  Future<void> _checkAccessibility() async {
    isAccessibilityEnabled.value = await _vpnService.isAccessibilityEnabled();
  }

  void _listenToVpnEvents() {
    _vpnService.vpnEventStream?.listen((event) {
      if (event is Map) {
        final type = event['type'];

        switch (type) {
          case 'status':
            final status = event['status'];
            isRunning.value = status == 'running';
            // Re-check accessibility whenever VPN status changes
            _checkAccessibility();
            break;

          case 'domain':
            final domain = event['domain'] as String?;
            if (domain != null && domain.isNotEmpty) {
              _handleDomainEvent(domain);
            }
            break;

          case 'error':
            // Errors are now handled by the UI layer
            break;
        }
      }
    });
  }

  /// Listen for full URL events from AccessibilityService
  void _listenToUrlEvents() {
    _vpnService.urlEventStream?.listen((event) {
      if (event is Map) {
        final type = event['type'];
        if (type == 'url') {
          final url = event['url'] as String?;
          final packageName = event['package'] as String?;
          if (url != null && url.isNotEmpty) {
            // If we're receiving URL events, accessibility IS enabled
            if (!isAccessibilityEnabled.value) {
              isAccessibilityEnabled.value = true;
            }
            _handleUrlEvent(url, packageName ?? 'unknown');
          }
        }
      }
    });
  }

  /// Returns 'started', 'no_accessibility', or 'error'
  Future<String> startVpn() async {
    final packages = trackAllApps.value ? null : await _getBrowserPackages();
    final success = await _vpnService.startVpn(allowedPackages: packages);
    if (success) {
      isRunning.value = true;
      await _checkAccessibility();
      if (!isAccessibilityEnabled.value) {
        return 'no_accessibility';
      }
      return 'started';
    }
    return 'error';
  }

  Future<bool> stopVpn() async {
    final success = await _vpnService.stopVpn();
    if (success) {
      isRunning.value = false;
      await _checkAccessibility();
      return true;
    }
    return false;
  }

  Future<void> openAccessibilitySettings() async {
    await _vpnService.openAccessibilitySettings();
  }

  void _handleUrlEvent(String url, String browserPackage) {
    // Extract domain from URL for classification
    String domain;
    try {
      final uri = Uri.parse(url);
      domain = uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      domain = url;
    }

    domain = _normalizeDomain(domain);
    if (domain.isEmpty) return;

    // Log with full URL info
    // ignore: avoid_print
    print('🌐 URL [$browserPackage]: $url (domain: $domain)');

    _handleDomainEvent(domain, fullUrl: url);
  }

  /// Validate & normalise a raw domain string.
  /// Returns '' for junk (encoded spaces, no dots, IPs, etc.).
  /// Strips subdomains down to the registrable root (keeps last 2 parts,
  /// or last 3 for two-letter TLDs like .co.id, .co.uk).
  static String _normalizeDomain(String raw) {
    var d = raw.trim().toLowerCase();

    // Reject encoded spaces / obvious non-domain text
    if (d.contains('%20') || d.contains(' ')) return '';

    // Must contain at least one dot to be a domain
    if (!d.contains('.')) return '';

    // Strip trailing dots
    while (d.endsWith('.')) {
      d = d.substring(0, d.length - 1);
    }

    // Extract root domain (collapse subdomains)
    final parts = d.split('.');
    if (parts.length <= 2) return d;

    // Handle two-letter second-level TLDs (co.id, co.uk, com.br, etc.)
    final sld = parts[parts.length - 2];
    if (sld.length <= 3 && parts.length >= 3) {
      return parts.sublist(parts.length - 3).join('.');
    }
    return parts.sublist(parts.length - 2).join('.');
  }

  void _handleDomainEvent(String domain, {String? fullUrl}) {
    domain = _normalizeDomain(domain);
    if (domain.isEmpty) return;

    // Check if domain should be skipped
    final skipDomains = _db.skipDomains.values;
    for (final skipDomain in skipDomains) {
      if (domain == skipDomain || domain.endsWith('.$skipDomain')) {
        return; // Skip - do not record this domain
      }
    }

    final now = DateTime.now();
    final userId = _authService.currentUser?.uid ?? '';

    // Calculate duration since last seen
    final lastSeen = _domainLastSeen[domain];
    final durationSeconds = lastSeen != null
        ? now.difference(lastSeen).inSeconds
        : 0;

    _domainLastSeen[domain] = now;

    // Classify domain
    final category = _classifier.classifyDomain(domain);

    // Trigger local notification for unsafe domains
    if (category != 'safe') {
      // ignore: avoid_print
      print(
        '⚠️ Unsafe domain detected: $domain → $category (notif=${isNotificationEnabled.value})',
      );
      if (isNotificationEnabled.value) {
        try {
          final notifService = Get.find<NotificationService>();
          notifService.showUnsafeDomainNotification(domain, category);
        } catch (e) {
          // ignore: avoid_print
          print('❌ Notification error: $e');
        }
      }
    }

    // Save to local database (raw domain, no hashing)
    final domainAccess = DomainAccess(
      domain: domain,
      timestamp: now,
      durationSeconds: durationSeconds,
      category: category,
      userId: userId,
      synced: false,
    );

    _db.domainAccess.add(domainAccess);

    // Update today's stats
    _calculateTodayStats();
  }

  /// Recalculate all statistics (called after pull from Firebase).
  void refreshStats() {
    _calculateTodayStats();
    _calculateWeeklyStats();
  }

  void _calculateTodayStats() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final userId = _authService.currentUser?.uid ?? '';

    final todayAccesses = _db.userDomainAccess(userId).where((access) {
      return access.timestamp.isAfter(startOfDay);
    }).toList();

    // Count unique domains
    final uniqueDomains = todayAccesses.map((a) => a.domain).toSet();
    todayDomainCount.value = uniqueDomains.length;

    // Calculate total duration
    final totalSeconds = todayAccesses.fold<int>(
      0,
      (sum, access) => sum + access.durationSeconds,
    );
    todayDurationMinutes.value = (totalSeconds / 60).round();

    // Top domains by visit count
    final domainCounts = <String, int>{};
    for (final a in todayAccesses) {
      domainCounts[a.domain] = (domainCounts[a.domain] ?? 0) + 1;
    }
    final sorted = domainCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    todayTopDomains.value = sorted.take(5).toList();

    // Category breakdown
    final catCounts = <String, int>{};
    for (final a in todayAccesses) {
      final cat = a.category;
      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
    }
    final catSorted = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    todayCategoryBreakdown.value = catSorted;
  }

  void _calculateWeeklyStats() {
    final now = DateTime.now();
    final counts = <int>[];
    var totalWeekSeconds = 0;
    final userId = _authService.currentUser?.uid ?? '';
    final allAccesses = _db.userDomainAccess(userId);

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));

      final dayAccesses = allAccesses.where((a) {
        return !a.timestamp.isBefore(day) && a.timestamp.isBefore(nextDay);
      }).toList();

      counts.add(dayAccesses.map((a) => a.domain).toSet().length);
      totalWeekSeconds += dayAccesses.fold<int>(
        0,
        (s, a) => s + a.durationSeconds,
      );
    }

    weeklyDailyCounts.value = counts;
    weeklyTotalMinutes.value = (totalWeekSeconds / 60).round();

    // Yesterday's count for comparison insight
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final dayAfter = yesterday.add(const Duration(days: 1));
    final yAccesses = allAccesses.where((a) {
      return !a.timestamp.isBefore(yesterday) && a.timestamp.isBefore(dayAfter);
    });
    yesterdayDomainCount.value = yAccesses.map((a) => a.domain).toSet().length;
    final yTotalSeconds = yAccesses.fold<num>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );
    yesterdayDurationMinutes.value = (yTotalSeconds / 60).round();
  }
}
