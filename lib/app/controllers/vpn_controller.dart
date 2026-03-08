import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsafe_flutter/data/services/vpn_service.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/domain_classifier.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';
import 'package:mindsafe_flutter/data/services/notification_service.dart';
import 'package:mindsafe_flutter/data/services/sync_service.dart';
import 'package:mindsafe_flutter/app/services/background_tracking_service.dart';

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

  /// Increments every time a domain access record is written to DB.
  /// Use this in History Screen Obx so it rebuilds on every new record,
  /// not only when unique domain count changes.
  final accessCount = 0.obs;

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

  // Accessibility-first deduplication
  final _a11yRecentDomains = <String, DateTime>{};
  static const _a11yDedupeWindowMs = 5000;

  // Session-based duration tracking (Accessibility path)
  // Tracks the domain currently open in the browser and when the session started.
  String? _activeA11yDomain;
  DateTime? _activeSessionStart;

  /// The domain currently being browsed (active a11y session). Null if no session.
  String? get activeSessionDomain => _activeA11yDomain;

  /// How many seconds the current active session has been open.
  int get activeSessionSeconds {
    final start = _activeSessionStart;
    if (_activeA11yDomain == null || start == null) return 0;
    return DateTime.now().difference(start).inSeconds;
  }

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
    _syncUserIdToBackground();
    // Consume any URLs tracked while app was closed
    _consumePendingUrls();
  }

  @override
  void onClose() {
    _closeActiveSession();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccessibility();
      _closeActiveSession();
      // App came back to foreground → consume URLs tracked in background
      _consumePendingUrls();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _closeActiveSession();
    }
  }

  /// Load trackAllApps preference from SharedPreferences
  Future<void> _loadTrackAllApps() async {
    final prefs = await SharedPreferences.getInstance();
    trackAllApps.value = prefs.getBool(_prefKeyTrackAll) ?? false;
  }

  /// Persist userId so BrowserMonitorService.kt can attribute pending records,
  /// and refresh stats / pull Firestore whenever the user logs in.
  void _syncUserIdToBackground() {
    final userId = _authService.currentUser?.uid ?? '';
    if (userId.isNotEmpty) setBackgroundUserId(userId);

    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await setBackgroundUserId(user.uid);
        _calculateTodayStats();
        _calculateWeeklyStats();
        await _consumePendingUrls();
        // Re-trigger Firestore pull now that VpnController is registered
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            Get.find<SyncService>().pullFromFirebase();
          } catch (_) {}
        });
      }
    });
  }

  /// Read pending URL events written by BrowserMonitorService.kt to
  /// SharedPreferences while the app was closed, convert them to DomainAccess
  /// records in Hive, then refresh the UI.
  Future<void> _consumePendingUrls() async {
    try {
      final pending = await consumePendingUrls();
      if (pending.isEmpty) return;

      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      // Group by URL to build session-like records
      String? prevDomain;
      DateTime? prevTime;

      for (final e in pending) {
        final url = e['url'] as String? ?? '';
        final tsMs = e['timestamp'] as int? ?? 0;
        final ts = DateTime.fromMillisecondsSinceEpoch(tsMs);

        String domain;
        try {
          domain = Uri.parse(url).host;
        } catch (_) {
          domain = url;
        }
        domain = _normalizeDomain(domain);
        if (domain.isEmpty) continue;

        final durSec = (prevDomain == domain && prevTime != null)
            ? ts.difference(prevTime).inSeconds.clamp(0, 3600)
            : 0;

        final category = _classifier.classifyDomain(domain);
        await _db.domainAccess.add(
          DomainAccess(
            domain: domain,
            timestamp: ts,
            durationSeconds: durSec,
            category: category,
            userId: userId,
            synced: false,
          ),
        );

        prevDomain = domain;
        prevTime = ts;
      }

      _calculateTodayStats();
      _calculateWeeklyStats();
    } catch (_) {}
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

  /// Refresh all monitoring status indicators (accessibility + notification).
  /// Called when the monitoring sheet is opened to show real-time state.
  void refreshMonitoringStatus() {
    _checkAccessibility();
    _loadNotificationPref();
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
            // Accessibility-first: if Accessibility Service is active,
            // it already captures exactly what the user visits in the browser
            // URL bar. VPN captures ALL DNS requests including CDN, trackers,
            // and background requests — which are noise, not user intent.
            // → Only use VPN events as fallback when Accessibility is NOT active.
            if (isAccessibilityEnabled.value) break;

            final rawDomain = event['domain'] as String?;
            if (rawDomain != null && rawDomain.isNotEmpty) {
              _handleDomainEvent(rawDomain, source: 'vpn');
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

  /// Cleans up stale entries from _a11yRecentDomains to prevent memory bloat.
  void _pruneA11yCache() {
    final now = DateTime.now();
    _a11yRecentDomains.removeWhere(
      (_, t) => now.difference(t).inMilliseconds > _a11yDedupeWindowMs * 10,
    );
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
    String domain;
    try {
      final uri = Uri.parse(url);
      domain = uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      domain = url;
    }

    domain = _normalizeDomain(domain);
    if (domain.isEmpty) return;

    // ignore: avoid_print
    print('🌐 URL [$browserPackage]: $url (domain: $domain)');

    // Update dedup map so VPN skips this domain
    _a11yRecentDomains[domain] = DateTime.now();
    _pruneA11yCache();

    // ── Session-based duration tracking ──────────────────────────────
    // If the user has navigated to a DIFFERENT domain, close the previous
    // session and persist its real duration before starting a new one.
    if (_activeA11yDomain != null && _activeA11yDomain != domain) {
      _closeActiveSession();
    }

    if (_activeA11yDomain != domain) {
      // New domain: open a fresh session and immediately record a
      // zero-duration entry so the domain appears in today's stats right away.
      _activeA11yDomain = domain;
      _activeSessionStart = DateTime.now();
      _handleDomainEvent(
        domain,
        fullUrl: url,
        source: 'accessibility',
        durationOverride: 0,
      );
    }
    // Same domain as before: session is still open — nothing to do.
  }

  /// Closes the active Accessibility session and saves the accumulated duration.
  void _closeActiveSession() {
    final domain = _activeA11yDomain;
    final start = _activeSessionStart;
    if (domain == null || start == null) return;

    final durationSeconds = DateTime.now().difference(start).inSeconds;
    if (durationSeconds > 0) {
      // ignore: avoid_print
      print('⏱️ [accessibility] session closed: $domain = ${durationSeconds}s');
      _handleDomainEvent(
        domain,
        source: 'accessibility',
        durationOverride: durationSeconds,
      );
    }

    _activeA11yDomain = null;
    _activeSessionStart = null;
  }

  /// Validate & normalise a raw domain string.
  /// Returns '' for junk (encoded spaces, no dots, short TLD, IPs, bare ccSLDs, etc.).
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
    final tld = parts.last;

    // TLD must be at least 2 characters (reject "tiktok.c" while typing)
    if (tld.length < 2) return '';

    // Reject pure IP addresses (digits only in all parts)
    if (parts.every((p) => int.tryParse(p) != null)) return '';

    // Reject bare ccSLD pairs (my.id, go.id, co.id, co.uk, ac.id, web.id, etc.)
    // These are "public suffix" pseudo-TLDs, not real registrable domains.
    // A real domain using these always has a third part: gopret.my.id
    const ccSldPrefixes = {
      'co',
      'go',
      'ac',
      'my',
      'web',
      'or',
      'sch',
      'mil',
      'biz',
      'net',
      'com',
      'org',
      'gov',
      'edu',
      'int',
      'id',
      'uk',
      'jp',
      'au',
      'br',
    };
    if (parts.length == 2 && ccSldPrefixes.contains(parts[0])) return '';

    if (parts.length <= 2) return d;

    // Handle two-letter second-level TLDs (co.id, co.uk, com.br, etc.)
    final sld = parts[parts.length - 2];
    if (sld.length <= 3 && parts.length >= 3) {
      return parts.sublist(parts.length - 3).join('.');
    }
    return parts.sublist(parts.length - 2).join('.');
  }

  void _handleDomainEvent(
    String domain, {
    String? fullUrl,
    String source = 'vpn',
    int? durationOverride, // null = use event-based calc (VPN fallback)
  }) {
    domain = _normalizeDomain(domain);
    if (domain.isEmpty) return;

    // Check if domain should be skipped
    final skipDomains = _db.skipDomains.values;
    for (final skipDomain in skipDomains) {
      if (domain == skipDomain || domain.endsWith('.$skipDomain')) {
        return;
      }
    }

    final now = DateTime.now();
    final userId = _authService.currentUser?.uid ?? '';

    // Duration logic:
    // - Accessibility path → uses durationOverride (session-based, accurate)
    // - VPN fallback path  → uses event-based delta (same as before)
    late final int durationSeconds;
    if (durationOverride != null) {
      durationSeconds = durationOverride;
    } else {
      final lastSeen = _domainLastSeen[domain];
      durationSeconds = lastSeen != null
          ? now.difference(lastSeen).inSeconds
          : 0;
      _domainLastSeen[domain] = now;
    }

    // ignore: avoid_print
    print('📌 [$source] recording domain: $domain');

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
    accessCount.value += 1; // triggers real-time rebuild in History Screen

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
