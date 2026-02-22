import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';

class VersionService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current app version (from pubspec.yaml at build time).
  final currentVersion = ''.obs;

  /// Latest version available (from Firestore).
  final latestVersion = ''.obs;

  /// Release notes for the latest version.
  final releaseNotes = ''.obs;

  /// Whether an update is available.
  final updateAvailable = false.obs;

  /// Whether the update is forced (user must update).
  final forceUpdate = false.obs;

  /// Play Store / download URL.
  final storeUrl = ''.obs;

  /// Initialize: read the current app version & check for updates.
  Future<VersionService> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion.value = info.version; // e.g. "0.1.0"
      debugPrint('📱 Current app version: ${info.version}');
    } catch (e) {
      currentVersion.value = '0.0.0';
      debugPrint('❌ PackageInfo error: $e');
    }
    return this;
  }

  /// Check Firestore for the latest published version.
  /// Call this after the app is fully initialised and the UI is visible.
  Future<void> checkForUpdate() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('version')
          .get();

      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      latestVersion.value = data['latestVersion'] ?? '';
      releaseNotes.value = data['releaseNotes'] ?? '';
      forceUpdate.value = data['forceUpdate'] ?? false;
      storeUrl.value = data['storeUrl'] ?? '';

      if (latestVersion.value.isNotEmpty &&
          _isNewer(latestVersion.value, currentVersion.value)) {
        updateAvailable.value = true;
        debugPrint('🆕 Update available: ${latestVersion.value}');
      }
    } catch (e) {
      debugPrint('❌ Version check error: $e');
    }
  }

  /// Show an update dialog. If [forceUpdate] is true the dialog is
  /// not dismissible.
  void showUpdateDialog(BuildContext context) {
    if (!updateAvailable.value) return;

    final theme = FTheme.of(context);

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate.value,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate.value,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: theme.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('version_update_available'.tr),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'version_new_version'.trParams({
                  'version': latestVersion.value,
                }),
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'version_current'.trParams({'version': currentVersion.value}),
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              if (releaseNotes.value.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'version_whats_new'.tr,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    releaseNotes.value,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
              if (forceUpdate.value) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'version_force_update'.tr,
                          style: theme.typography.xs.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!forceUpdate.value)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('version_later'.tr),
              ),
            FilledButton(
              onPressed: () {
                // TODO: Open Play Store URL using url_launcher
                // For now, just dismiss
                if (!forceUpdate.value) Navigator.of(ctx).pop();
              },
              child: Text('version_update_now'.tr),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Admin: publish a new version to Firestore ─────────────

  /// Admin publishes version info so all users see the update prompt.
  Future<void> publishVersion({
    required String version,
    required String notes,
    required bool force,
    String playStoreUrl = '',
  }) async {
    await _firestore.collection('app_config').doc('version').set({
      'latestVersion': version,
      'releaseNotes': notes,
      'forceUpdate': force,
      'storeUrl': playStoreUrl,
      'publishedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Published version $version to Firestore');
  }

  // ─── Helpers ───────────────────────────────────────────────

  /// Returns true if [latest] is a higher semver than [current].
  bool _isNewer(String latest, String current) {
    final latestParts = latest.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final l = (i < latestParts.length ? latestParts[i] : 0) ?? 0;
      final c = (i < currentParts.length ? currentParts[i] : 0) ?? 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false; // equal
  }
}
