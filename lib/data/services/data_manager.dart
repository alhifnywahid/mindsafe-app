import 'package:get/get.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/app/controllers/vpn_controller.dart';

class DataManager extends GetxService {
  final LocalDatabase _db = Get.find<LocalDatabase>();

  /// Delete data older than retention days
  Future<int> enforceRetention() async {
    final settings = _db.settings.get('default');
    final retentionDays = settings?.dataRetentionDays ?? 30;

    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final toDelete = <dynamic>[];

    for (final entry in _db.domainAccess.toMap().entries) {
      if (entry.value.timestamp.isBefore(cutoff)) {
        toDelete.add(entry.key);
      }
    }

    for (final key in toDelete) {
      await _db.domainAccess.delete(key);
    }

    return toDelete.length;
  }

  /// Delete all browsing data (local + Firebase)
  Future<void> deleteAllBrowsingData() async {
    // Delete local data
    await _db.domainAccess.clear();

    // Delete from Firebase too (user privacy)
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.deleteAllDomainAccesses();
    } catch (e) {
      // ignore: avoid_print
      print('Firebase delete error: $e');
    }

    // Refresh UI stats to reflect empty data
    try {
      final vpnCtrl = Get.find<VpnController>();
      vpnCtrl.refreshStats();
    } catch (_) {}
  }

  /// Delete all user data (browsing data + settings)
  Future<void> deleteAllUserData() async {
    await deleteAllBrowsingData();
    await _db.settings.clear();
  }
}
