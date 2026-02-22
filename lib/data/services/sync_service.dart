import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';

class SyncService extends GetxService {
  final LocalDatabase _db = Get.find<LocalDatabase>();
  final FirestoreRepository _firestoreRepo = Get.find<FirestoreRepository>();

  final isSyncing = false.obs;
  final lastSyncTime = Rxn<DateTime>();
  final pendingCount = 0.obs;

  Timer? _syncTimer;
  StreamSubscription? _connectivitySub;

  Future<SyncService> init() async {
    // Listen for connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        syncNow();
      }
    });

    // Periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncNow());

    // Update pending count
    _updatePendingCount();

    return this;
  }

  void _updatePendingCount() {
    final userId = Get.find<AuthService>().currentUser?.uid ?? '';
    final unsynced = _db
        .userDomainAccess(userId)
        .where((a) => !a.synced)
        .toList();
    pendingCount.value = unsynced.length;
  }

  Future<void> syncNow() async {
    if (isSyncing.value) return;

    isSyncing.value = true;
    try {
      final userId = Get.find<AuthService>().currentUser?.uid ?? '';
      final unsynced = _db
          .userDomainAccess(userId)
          .where((a) => !a.synced)
          .toList();
      if (unsynced.isEmpty) {
        isSyncing.value = false;
        return;
      }

      final count = await _firestoreRepo.syncDomainAccesses(unsynced);

      if (count > 0) {
        // Mark as synced
        for (final access in unsynced) {
          access.synced = true;
          access.save();
        }
        lastSyncTime.value = DateTime.now();
      }

      _updatePendingCount();
    } catch (e) {
      // ignore: avoid_print
      print('Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _connectivitySub?.cancel();
    super.onClose();
  }
}
