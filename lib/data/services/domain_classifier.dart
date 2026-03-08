import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mindsafe_flutter/data/models/domain_rule.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';

/// Maps a blocklist file name (without extension) to its app category label.
const _blocklistCategories = <String, String>{
  'adult': 'adult',
  'gambling': 'gambling',
  'phishing': 'phishing',
  'malware': 'malware',
  'cryptojacking': 'cryptojacking',
  'drugs': 'drugs',
  'hacking': 'hacking',
  'dangerius': 'dangerous',
  'dating': 'dating',
  'ddos': 'ddos',
  'warez': 'warez',
};

/// Parses raw text content (one domain per line) into a Set.
/// Runs inside an isolate so heavy file parsing doesn't block the UI.
Set<String> _parseDomainsInIsolate(String content) {
  final set = <String>{};
  final lines = content.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
      set.add(trimmed.toLowerCase());
    }
  }
  return set;
}

class DomainClassifier extends GetxService {
  final LocalDatabase _db = Get.find<LocalDatabase>();

  /// Category → set of blocked domains.
  final Map<String, Set<String>> _blocklists = {};

  /// Whether the initial load has completed.
  final isLoaded = false.obs;

  /// Total number of domains across all loaded blocklists.
  final totalDomains = 0.obs;

  /// Number of custom domain rules (reactive).
  final rulesCount = 0.obs;

  /// Number of skip domains (reactive).
  final skipDomainsCount = 0.obs;

  /// Load all blocklist assets. Call once during app startup.
  Future<DomainClassifier> init() async {
    await _loadAllBlocklists();
    await syncRulesFromFirestore();
    await syncSkipDomainsFromFirestore();
    // Initialise reactive counters after sync
    rulesCount.value = _db.domainRules.length;
    skipDomainsCount.value = _db.skipDomains.length;
    return this;
  }

  // ─── Loading ──────────────────────────────────────────────

  Future<void> _loadAllBlocklists() async {
    // Load each blocklist category in sequence to limit peak memory.
    for (final entry in _blocklistCategories.entries) {
      final fileName = entry.key;
      final category = entry.value;
      try {
        final content = await rootBundle.loadString(
          'assets/blocklists/$fileName.txt',
          cache: false,
        );

        // Parse in an isolate so the main thread stays responsive.
        final domainSet = await Isolate.run(
          () => _parseDomainsInIsolate(content),
        );

        _blocklists[category] = domainSet;
        totalDomains.value += domainSet.length;
      } catch (e) {
        // File might not exist – skip silently.
      }
    }
    isLoaded.value = true;
  }

  // ─── Classification ───────────────────────────────────────

  /// Classify a domain. First checks custom rules from the database,
  /// then checks the embedded UT1 blocklists.
  /// Returns: 'adult', 'gambling', 'phishing', … or 'safe'.
  String classifyDomain(String domain) {
    final lowerDomain = domain.toLowerCase();

    // 1) Check custom rules from Hive (admin-defined)
    final customResult = _checkCustomRules(lowerDomain);
    if (customResult != null) return customResult;

    // 2) Check UT1 blocklists (embedded assets)
    final blocklistResult = _checkBlocklists(lowerDomain);
    if (blocklistResult != null) return blocklistResult;

    // 3) Nothing matched → safe
    return 'safe';
  }

  String? _checkCustomRules(String domain) {
    final rules = _db.domainRules.values.where((r) => r.isActive).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    for (var rule in rules) {
      if (rule.isRegex) {
        final regex = RegExp(rule.pattern);
        if (regex.hasMatch(domain)) return rule.category;
      } else {
        if (domain == rule.pattern ||
            domain.contains(rule.pattern) ||
            domain.endsWith('.${rule.pattern}')) {
          return rule.category;
        }
      }
    }
    return null;
  }

  String? _checkBlocklists(String domain) {
    // Check exact match first, then check parent domain.
    // e.g. for "www.xxx.com", also check "xxx.com".
    for (final entry in _blocklists.entries) {
      final category = entry.key;
      final domains = entry.value;

      // Exact match
      if (domains.contains(domain)) return category;

      // Parent domain match  (strip leading subdomain parts one-by-one)
      final parts = domain.split('.');
      for (int i = 1; i < parts.length - 1; i++) {
        final parent = parts.sublist(i).join('.');
        if (domains.contains(parent)) return category;
      }
    }
    return null;
  }

  // ─── CRUD for custom rules (admin) ────────────────────────

  Future<void> addRule(DomainRule rule) async {
    await _db.domainRules.put(rule.id, rule);
    rulesCount.value = _db.domainRules.length;
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.saveDomainRule(rule);
    } catch (e) {
      debugPrint('⚠️ Firestore rule sync skipped: $e');
    }
  }

  Future<void> updateRule(DomainRule rule) async {
    await _db.domainRules.put(rule.id, rule);
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.saveDomainRule(rule);
    } catch (e) {
      debugPrint('⚠️ Firestore rule sync skipped: $e');
    }
  }

  Future<void> deleteRule(String id) async {
    await _db.domainRules.delete(id);
    rulesCount.value = _db.domainRules.length;
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.deleteDomainRule(id);
    } catch (e) {
      debugPrint('⚠️ Firestore rule delete skipped: $e');
    }
  }

  List<DomainRule> getAllRules() {
    return _db.domainRules.values.toList();
  }

  // ─── Sync rules FROM Firestore → local Hive ──────────────

  /// Download all domain rules from Firestore and merge into local Hive.
  /// This ensures every user device has the latest admin rules.
  Future<void> syncRulesFromFirestore() async {
    try {
      final repo = Get.find<FirestoreRepository>();
      final remoteRules = await repo.fetchDomainRules();

      if (remoteRules.isEmpty) return;

      // Merge: remote rules overwrite local if same ID
      for (final rule in remoteRules) {
        await _db.domainRules.put(rule.id, rule);
      }

      debugPrint('✅ Synced ${remoteRules.length} rules from Firestore');
    } catch (e) {
      debugPrint('⚠️ Rules sync from Firestore skipped: $e');
    }
  }

  // ─── CRUD for skip domains (admin) ────────────────────────

  Future<void> addSkipDomain(String domain) async {
    await _db.skipDomains.add(domain);
    skipDomainsCount.value = _db.skipDomains.length;
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.saveSkipDomain(domain);
    } catch (e) {
      debugPrint('⚠️ Firestore skip domain sync skipped: $e');
    }
  }

  Future<void> deleteSkipDomain(String domain) async {
    final key = _db.skipDomains.keys.firstWhere(
      (k) => _db.skipDomains.get(k) == domain,
      orElse: () => null,
    );
    if (key != null) {
      await _db.skipDomains.delete(key);
      skipDomainsCount.value = _db.skipDomains.length;
    }
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.deleteSkipDomain(domain);
    } catch (e) {
      debugPrint('⚠️ Firestore skip domain delete skipped: $e');
    }
  }

  /// Download all skip domains from Firestore and merge into local Hive.
  Future<void> syncSkipDomainsFromFirestore() async {
    try {
      final repo = Get.find<FirestoreRepository>();
      final remoteDomains = await repo.fetchSkipDomains();

      if (remoteDomains.isEmpty) return;

      final localDomains = _db.skipDomains.values.toSet();
      for (final domain in remoteDomains) {
        if (!localDomains.contains(domain)) {
          await _db.skipDomains.add(domain);
        }
      }

      debugPrint(
        '✅ Synced ${remoteDomains.length} skip domains from Firestore',
      );
    } catch (e) {
      debugPrint('⚠️ Skip domains sync from Firestore skipped: $e');
    }
  }
}
