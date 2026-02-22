import 'package:get/get.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';

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

  /// Delete all browsing data
  Future<void> deleteAllBrowsingData() async {
    await _db.domainAccess.clear();
  }

  /// Delete all user data (browsing data + settings)
  Future<void> deleteAllUserData() async {
    await _db.domainAccess.clear();
    await _db.settings.clear();
  }
}
