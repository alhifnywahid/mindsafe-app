import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';
import 'package:mindsafe_flutter/data/models/domain_rule.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';

class FirestoreRepository extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── User Profile ─────────────────────────────────────────

  /// Save user profile to Firestore (called on every login).
  Future<void> saveUserProfile({
    required String userId,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'displayName': displayName ?? '',
        'email': email ?? '',
        'photoUrl': photoUrl ?? '',
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ User profile saved to Firestore');
    } catch (e) {
      debugPrint('❌ Save user profile error: $e');
    }
  }

  /// Check if user has completed registration form.
  Future<bool> checkUserRegistered(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return false;
      return doc.data()!['isRegistered'] == true;
    } catch (e) {
      debugPrint('❌ Check registration error: $e');
      return false;
    }
  }

  /// Save registration form data and mark user as registered.
  Future<void> saveRegistrationData({
    required String userId,
    required String nickname,
    required String ageCategory,
    required String gender,
    required int dataRetentionDays,
    required bool monitoringConsent,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'nickname': nickname,
        'ageCategory': ageCategory,
        'gender': gender,
        'dataRetentionDays': dataRetentionDays,
        'monitoringConsent': monitoringConsent,
        'isRegistered': true,
        'registeredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Registration data saved to Firestore');
    } catch (e) {
      debugPrint('❌ Save registration data error: $e');
      rethrow;
    }
  }

  // ─── Domain Access Sync ───────────────────────────────────

  /// Upload unsynced domain accesses to Firestore.
  Future<int> syncDomainAccesses(List<DomainAccess> unsynced) async {
    if (unsynced.isEmpty) return 0;

    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.uid;
    if (userId == null) return 0;

    int count = 0;

    // Firestore batch limit is 500; split into chunks
    final chunks = <List<DomainAccess>>[];
    for (var i = 0; i < unsynced.length; i += 400) {
      chunks.add(
        unsynced.sublist(
          i,
          i + 400 > unsynced.length ? unsynced.length : i + 400,
        ),
      );
    }

    for (final chunk in chunks) {
      final batch = _firestore.batch();
      for (final access in chunk) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('domain_accesses')
            .doc();

        batch.set(docRef, {
          'domain': access.domain,
          'timestamp': Timestamp.fromDate(access.timestamp),
          'durationSeconds': access.durationSeconds,
          'category': access.category,
          'userId': userId,
        });
        count++;
      }
      await batch.commit();
    }

    debugPrint('✅ Synced $count domain accesses to Firestore');
    return count;
  }

  /// Fetch all domain accesses from Firestore for the current user.
  Future<List<DomainAccess>> fetchDomainAccesses() async {
    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('domain_accesses')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DomainAccess(
          domain: data['domain'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          durationSeconds: data['durationSeconds'] ?? 0,
          category: data['category'] ?? 'safe',
          synced: true, // Already in Firebase
          userId: userId,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Fetch domain accesses error: $e');
      return [];
    }
  }

  /// Delete all domain accesses from Firestore for the current user.
  Future<void> deleteAllDomainAccesses() async {
    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.uid;
    if (userId == null) return;

    try {
      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('domain_accesses');

      // Delete in batches of 400
      QuerySnapshot snapshot;
      do {
        snapshot = await collection.limit(400).get();
        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } while (snapshot.docs.length == 400);

      debugPrint('✅ All domain accesses deleted from Firestore');
    } catch (e) {
      debugPrint('❌ Delete domain accesses error: $e');
    }
  }

  // ─── Domain Rules (Admin) ─────────────────────────────────

  /// Save a domain rule to Firestore (global, shared across all users).
  Future<void> saveDomainRule(DomainRule rule) async {
    try {
      await _firestore
          .collection('domain_rules')
          .doc(rule.id)
          .set(rule.toMap());
      debugPrint('✅ Domain rule saved to Firestore: ${rule.pattern}');
    } catch (e) {
      debugPrint('❌ Save domain rule error: $e');
    }
  }

  /// Delete a domain rule from Firestore.
  Future<void> deleteDomainRule(String ruleId) async {
    try {
      await _firestore.collection('domain_rules').doc(ruleId).delete();
      debugPrint('✅ Domain rule deleted from Firestore: $ruleId');
    } catch (e) {
      debugPrint('❌ Delete domain rule error: $e');
    }
  }

  /// Fetch all domain rules from Firestore (for user-side sync).
  Future<List<DomainRule>> fetchDomainRules() async {
    try {
      final snap = await _firestore.collection('domain_rules').get();
      return snap.docs.map((doc) => DomainRule.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('❌ Fetch domain rules error: $e');
      return [];
    }
  }

  // ─── Skip Domains (Admin) ──────────────────────────────────

  /// Save a skip domain to Firestore (global, shared across all users).
  Future<void> saveSkipDomain(String domain) async {
    try {
      await _firestore.collection('skip_domains').doc(domain).set({
        'domain': domain,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Skip domain saved to Firestore: $domain');
    } catch (e) {
      debugPrint('❌ Save skip domain error: $e');
    }
  }

  /// Delete a skip domain from Firestore.
  Future<void> deleteSkipDomain(String domain) async {
    try {
      await _firestore.collection('skip_domains').doc(domain).delete();
      debugPrint('✅ Skip domain deleted from Firestore: $domain');
    } catch (e) {
      debugPrint('❌ Delete skip domain error: $e');
    }
  }

  /// Fetch all skip domains from Firestore.
  Future<List<String>> fetchSkipDomains() async {
    try {
      final snap = await _firestore.collection('skip_domains').get();
      return snap.docs
          .map((doc) => doc.data()['domain'] as String? ?? doc.id)
          .toList();
    } catch (e) {
      debugPrint('❌ Fetch skip domains error: $e');
      return [];
    }
  }

  // ─── Admin Stats ──────────────────────────────────────────

  /// Get aggregate stats for admin dashboard.
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final rulesSnap = await _firestore.collection('domain_rules').get();

      return {
        'userCount': usersSnap.docs.length,
        'ruleCount': rulesSnap.docs.length,
        'status': 'healthy',
      };
    } catch (e) {
      return {
        'userCount': 0,
        'ruleCount': 0,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Get aggregated domain stats from ALL users for admin dashboard.
  /// Returns: category breakdown and domain list sorted by duration.
  Future<Map<String, dynamic>> getAllUsersDomainStats({
    int limitPerUser = 500,
  }) async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      debugPrint(
        '🔍 getAllUsersDomainStats: found ${usersSnap.docs.length} users',
      );

      final categoryMap = <String, int>{}; // category → total visits
      final domainVisits = <String, int>{}; // domain → total visits
      final domainDuration = <String, int>{}; // domain → total duration seconds
      final domainCategory = <String, String>{}; // domain → category

      for (final userDoc in usersSnap.docs) {
        final accessesSnap = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('domain_accesses')
            .limit(limitPerUser)
            .get();
        debugPrint(
          '  └─ user ${userDoc.id}: ${accessesSnap.docs.length} domain_accesses',
        );

        for (final doc in accessesSnap.docs) {
          final data = doc.data();
          final domain = (data['domain'] as String? ?? '').toLowerCase();
          final category = data['category'] as String? ?? 'safe';
          final duration = (data['durationSeconds'] as num? ?? 0).toInt();

          if (domain.isEmpty) continue;

          // Category breakdown
          categoryMap[category] = (categoryMap[category] ?? 0) + 1;

          // Domain aggregation
          domainVisits[domain] = (domainVisits[domain] ?? 0) + 1;
          domainDuration[domain] = (domainDuration[domain] ?? 0) + duration;
          domainCategory[domain] = category; // last wins; usually consistent
        }
      }

      // Build sorted domain list (descending by duration)
      final domainList =
          domainVisits.keys.map((domain) {
            return {
              'domain': domain,
              'visits': domainVisits[domain] ?? 0,
              'durationSeconds': domainDuration[domain] ?? 0,
              'category': domainCategory[domain] ?? 'safe',
            };
          }).toList()..sort(
            (a, b) => (b['durationSeconds'] as int).compareTo(
              a['durationSeconds'] as int,
            ),
          );

      // Category list sorted by visits descending
      final categoryList =
          categoryMap.entries
              .map((e) => {'category': e.key, 'visits': e.value})
              .toList()
            ..sort(
              (a, b) => (b['visits'] as int).compareTo(a['visits'] as int),
            );

      return {
        'categoryBreakdown': categoryList,
        'domainList': domainList,
        'totalEntries': domainVisits.values.fold(0, (s, v) => s + v),
      };
    } catch (e) {
      debugPrint('❌ getAllUsersDomainStats error: $e');
      return {'categoryBreakdown': [], 'domainList': [], 'totalEntries': 0};
    }
  }

  /// Get user list for admin.
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final snap = await _firestore.collection('users').get();
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get browsing stats for a specific user (admin view).
  Future<Map<String, dynamic>> getUserBrowsingStats(String userId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('domain_accesses')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final totalAccesses = snap.docs.length;
      final categories = <String, int>{};
      int totalDuration = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final cat = data['category'] ?? 'safe';
        categories[cat] = (categories[cat] ?? 0) + 1;
        totalDuration += (data['durationSeconds'] ?? 0) as int;
      }

      return {
        'totalAccesses': totalAccesses,
        'categories': categories,
        'totalDurationMinutes': (totalDuration / 60).round(),
      };
    } catch (e) {
      return {'totalAccesses': 0, 'categories': {}, 'totalDurationMinutes': 0};
    }
  }

  // ─── Delete User Data ─────────────────────────────────────

  /// Delete all user data from Firestore.
  Future<void> deleteUserData(String userId) async {
    // Delete domain accesses
    final accessesSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('domain_accesses')
        .get();

    final batch = _firestore.batch();
    for (final doc in accessesSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete user document
    await _firestore.collection('users').doc(userId).delete();
    debugPrint('✅ All user data deleted from Firestore');
  }

  // ─── Push Notifications (Admin) ───────────────────────────

  /// Send a global push notification (stored in Firestore).
  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final authService = Get.find<AuthService>();
    await _firestore.collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'sentBy': authService.currentUser?.email ?? 'admin',
      'sentAt': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Notification sent: $title');
  }

  /// Get recent notifications (admin view).
  Future<List<Map<String, dynamic>>> getNotifications({int limit = 20}) async {
    try {
      final snap = await _firestore
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('❌ Get notifications error: $e');
      return [];
    }
  }

  /// Delete a notification from Firestore.
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
