import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/sync_service.dart';
import 'package:mindsafe_flutter/data/services/data_manager.dart';
import 'package:mindsafe_flutter/app/controllers/vpn_controller.dart';
import 'package:mindsafe_flutter/app/controllers/theme_controller.dart';
import 'package:mindsafe_flutter/app/controllers/language_controller.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';
import 'package:mindsafe_flutter/core/widgets/app_card.dart';
import 'package:mindsafe_flutter/core/widgets/app_bottom_sheet.dart';
import 'package:mindsafe_flutter/core/widgets/settings_sheet.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';
import 'package:mindsafe_flutter/screens/settings/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final authService = Get.find<AuthService>();
    final db = Get.find<LocalDatabase>();
    final isAdmin = authService.isAdmin;
    final vpnController = isAdmin ? null : Get.find<VpnController>();
    final syncService = Get.find<SyncService>();

    return FScaffold(
      header: FHeader(
        title: Text(
          'settings_title'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: authService.currentUser?.photoURL != null
                        ? NetworkImage(authService.currentUser!.photoURL!)
                        : null,
                    child: authService.currentUser?.photoURL == null
                        ? Icon(
                            Icons.person,
                            size: 28,
                            color: theme.colors.mutedForeground,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.currentUser?.displayName ?? 'User',
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colors.foreground,
                          ),
                        ),
                        Text(
                          authService.currentUser?.email ?? '',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        if (authService.isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colors.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'home_admin_badge'.tr,
                              style: theme.typography.xs.copyWith(
                                color: theme.colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Appearance ───
            _SectionTitle('settings_appearance'.tr, theme),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              child: Column(
                children: [
                  // Theme
                  Obx(() {
                    final themeCtrl = Get.find<ThemeController>();
                    return _SettingRow(
                      icon: themeCtrl.themeIcon,
                      title: 'settings_theme'.tr,
                      subtitle: themeCtrl.themeModeLabel,
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colors.mutedForeground,
                      ),
                      onTap: () => showSettingsSheet<ThemeMode>(
                        context: context,
                        title: 'settings_theme'.tr,
                        description: 'sheet_theme_desc'.tr,
                        selectedValue: themeCtrl.themeMode,
                        options: [
                          SettingsOption(
                            value: ThemeMode.light,
                            icon: Icons.light_mode,
                            label: 'settings_theme_light'.tr,
                            description: 'sheet_theme_light_desc'.tr,
                          ),
                          SettingsOption(
                            value: ThemeMode.dark,
                            icon: Icons.dark_mode,
                            label: 'settings_theme_dark'.tr,
                            description: 'sheet_theme_dark_desc'.tr,
                          ),
                          SettingsOption(
                            value: ThemeMode.system,
                            icon: Icons.brightness_auto,
                            label: 'settings_theme_system'.tr,
                            description: 'sheet_theme_system_desc'.tr,
                          ),
                        ],
                        onSelected: (mode) => themeCtrl.setThemeMode(mode),
                      ),
                      theme: theme,
                    );
                  }),

                  Divider(color: theme.colors.border, height: 1),

                  // Language
                  Obx(() {
                    final langCtrl = Get.find<LanguageController>();
                    return _SettingRow(
                      icon: Icons.language,
                      title: 'settings_language'.tr,
                      subtitle: langCtrl.currentLanguageLabel,
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colors.mutedForeground,
                      ),
                      onTap: () => showSettingsSheet<Locale>(
                        context: context,
                        title: 'settings_language'.tr,
                        description: 'sheet_language_desc'.tr,
                        selectedValue: Get.locale,
                        options: [
                          SettingsOption(
                            value: const Locale('en', 'US'),
                            icon: Icons.language,
                            label: 'settings_language_en'.tr,
                            description: 'sheet_language_en_desc'.tr,
                          ),
                          SettingsOption(
                            value: const Locale('id', 'ID'),
                            icon: Icons.language,
                            label: 'settings_language_id'.tr,
                            description: 'sheet_language_id_desc'.tr,
                          ),
                        ],
                        onSelected: (locale) => langCtrl.setLocale(locale),
                      ),
                      theme: theme,
                    );
                  }),
                ],
              ),
            ),

            if (!isAdmin) ...[
              const SizedBox(height: AppSpacing.lg),

              // ─── Monitoring & Data (merged) ───
              _SectionTitle('settings_monitoring'.tr, theme),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                child: Column(
                  children: [
                    // Track All Apps
                    Obx(
                      () => _SettingRow(
                        icon: Icons.apps,
                        title: 'settings_track_all_apps'.tr,
                        subtitle: vpnController!.trackAllApps.value
                            ? 'settings_track_all_apps_on'.tr
                            : 'settings_track_all_apps_off'.tr,
                        trailing: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: theme.colors.mutedForeground,
                        ),
                        onTap: () => showSettingsSheet<bool>(
                          context: context,
                          title: 'settings_track_all_apps'.tr,
                          description: 'sheet_track_apps_desc'.tr,
                          selectedValue: vpnController.trackAllApps.value,
                          options: [
                            SettingsOption(
                              value: true,
                              icon: Icons.apps,
                              label: 'settings_track_all_apps_on'.tr,
                              description: 'sheet_track_on_desc'.tr,
                            ),
                            SettingsOption(
                              value: false,
                              icon: Icons.app_blocking,
                              label: 'settings_track_all_apps_off'.tr,
                              description: 'sheet_track_off_desc'.tr,
                            ),
                          ],
                          onSelected: (v) => vpnController.setTrackAllApps(v),
                        ),
                        theme: theme,
                      ),
                    ),

                    Divider(color: theme.colors.border, height: 1),

                    // Cloud Sync Status
                    Obx(
                      () => _SettingRow(
                        icon: Icons.cloud_sync,
                        title: 'settings_sync_status'.tr,
                        subtitle: syncService.isSyncing.value
                            ? 'settings_syncing'.tr
                            : syncService.lastSyncTime.value != null
                            ? 'settings_last_sync'.trParams({
                                'time': _formatTime(
                                  syncService.lastSyncTime.value!,
                                ),
                              })
                            : 'settings_never_synced'.tr,
                        trailing: syncService.isSyncing.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        theme: theme,
                      ),
                    ),

                    Divider(color: theme.colors.border, height: 1),

                    // Pending Records
                    Obx(
                      () => _SettingRow(
                        icon: Icons.pending_actions,
                        title: 'settings_pending'.tr,
                        subtitle: 'settings_pending_count'.trParams({
                          'count': '${syncService.pendingCount.value}',
                        }),
                        trailing: syncService.pendingCount.value > 0
                            ? IconButton(
                                icon: Icon(
                                  Icons.sync,
                                  color: theme.colors.primary,
                                  size: 20,
                                ),
                                onPressed: () => syncService.syncNow(),
                              )
                            : null,
                        theme: theme,
                      ),
                    ),

                    Divider(color: theme.colors.border, height: 1),

                    // Data Retention
                    _SettingRow(
                      icon: Icons.auto_delete,
                      title: 'settings_data_retention'.tr,
                      subtitle: 'settings_days'.trParams({
                        'count':
                            '${db.settings.get('default')?.dataRetentionDays ?? 30}',
                      }),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colors.mutedForeground,
                      ),
                      onTap: () {
                        final currentDays =
                            db.settings.get('default')?.dataRetentionDays ?? 30;
                        showSettingsSheet<int>(
                          context: context,
                          title: 'settings_data_retention'.tr,
                          description: 'sheet_retention_desc'.tr,
                          selectedValue: currentDays,
                          options: [7, 14, 30, 60, 90]
                              .map(
                                (d) => SettingsOption(
                                  value: d,
                                  icon: Icons.calendar_today,
                                  label: 'settings_days'.trParams({
                                    'count': '$d',
                                  }),
                                  description: 'sheet_retention_option_desc'
                                      .trParams({'count': '$d'}),
                                ),
                              )
                              .toList(),
                          onSelected: (days) {
                            final settings = db.settings.get('default');
                            if (settings != null) {
                              settings.dataRetentionDays = days;
                              settings.save();
                              Get.snackbar(
                                'settings_updated'.tr,
                                'settings_retention_set'.trParams({
                                  'count': '$days',
                                }),
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                        );
                      },
                      theme: theme,
                    ),

                    Divider(color: theme.colors.border, height: 1),

                    // Delete Browsing Data
                    _SettingRow(
                      icon: Icons.delete_outline,
                      title: 'settings_delete_data'.tr,
                      subtitle: 'settings_delete_data_desc'.tr,
                      iconColor: theme.colors.error,
                      onTap: () => _confirmDeleteDataSheet(context, db),
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ], // end if (!isAdmin)

            const SizedBox(height: AppSpacing.lg),

            // ─── Tentang Aplikasi ───
            _SectionTitle('about_section'.tr, theme),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  AboutRow(
                    icon: Icons.system_update_outlined,
                    title: 'about_check_update'.tr,
                    onTap: () => _openPlayStore(),
                    theme: theme,
                  ),
                  Divider(color: theme.colors.border, height: 1),
                  AboutRow(
                    icon: Icons.share_outlined,
                    title: 'about_share'.tr,
                    onTap: () => _shareApp(),
                    theme: theme,
                  ),
                  Divider(color: theme.colors.border, height: 1),
                  AboutRow(
                    icon: Icons.quiz_outlined,
                    title: 'about_faq'.tr,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                    theme: theme,
                  ),
                  Divider(color: theme.colors.border, height: 1),
                  AboutRow(
                    icon: Icons.feedback_outlined,
                    title: 'about_feedback'.tr,
                    onTap: () => _openFeedback(),
                    theme: theme,
                  ),
                  Divider(color: theme.colors.border, height: 1),
                  AboutRow(
                    icon: Icons.groups_outlined,
                    title: 'about_social'.tr,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SocialMediaScreen(),
                      ),
                    ),
                    theme: theme,
                  ),
                  Divider(color: theme.colors.border, height: 1),
                  AboutRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'about_privacy_policy'.tr,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalPage(
                          title: 'about_privacy_policy'.tr,
                          content: 'about_privacy_content'.tr,
                        ),
                      ),
                    ),
                    theme: theme,
                  ),
                  Divider(color: theme.colors.border, height: 1),
                  AboutRow(
                    icon: Icons.description_outlined,
                    title: 'about_terms'.tr,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalPage(
                          title: 'about_terms'.tr,
                          content: 'about_terms_content'.tr,
                        ),
                      ),
                    ),
                    theme: theme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sign Out
            SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => _confirmSignOut(context, authService, theme),
                prefix: const Icon(Icons.logout),
                child: Text('settings_sign_out'.tr),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // App info
            Center(
              child: Text(
                'settings_version'.tr,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _confirmSignOut(
    BuildContext context,
    AuthService authService,
    FThemeData theme,
  ) {
    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (ctx) => AppBottomSheet(
        children: [
          Icon(Icons.logout_rounded, size: 40, color: theme.colors.error),
          const SizedBox(height: 12),
          Text(
            'dialog_confirm_sign_out'.tr,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'dialog_confirm_sign_out_desc'.tr,
            textAlign: TextAlign.center,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.pop(ctx),
                  child: Text('dialog_cancel'.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FButton(
                  variant: FButtonVariant.destructive,
                  onPress: () async {
                    Navigator.pop(ctx);
                    await authService.signOut();
                    Get.offAllNamed(AppRoutes.login);
                  },
                  child: Text('settings_sign_out'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDataSheet(BuildContext context, LocalDatabase db) async {
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'dialog_confirm_delete_data'.tr,
      description: 'dialog_confirm_delete_data_desc'.tr,
      confirmLabel: 'dialog_delete'.tr,
      icon: Icons.delete_outline,
    );
    if (confirmed == true) {
      final dataManager = Get.find<DataManager>();
      dataManager.deleteAllBrowsingData();
      Get.snackbar(
        'dialog_done'.tr,
        'dialog_all_data_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─── About helpers ───

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mindsafe.app';
  static const _feedbackUrl = 'https://forms.google.com/mindsafe-feedback';

  void _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(text: '${'about_share_text'.tr}\n$_playStoreUrl'),
    );
  }

  void _openFeedback() async {
    final uri = Uri.parse(_feedbackUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final FThemeData theme;

  const _SectionTitle(this.title, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.typography.xs.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  final FThemeData theme;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colors.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colors.foreground,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
