import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/app/controllers/vpn_controller.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/notification_service.dart';

/// Format raw minutes into decomposed duration string: Xd Xh Xm
String _formatDuration(int totalMinutes) {
  if (totalMinutes <= 0) return '0m';
  final d = totalMinutes ~/ 1440;
  final h = (totalMinutes % 1440) ~/ 60;
  final m = totalMinutes % 60;
  final parts = <String>[];
  if (d > 0) parts.add('${d}d');
  if (h > 0) parts.add('${h}h');
  if (m > 0 || parts.isEmpty) parts.add('${m}m');
  return parts.join(' ');
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => VpnController());

    final auth = Get.find<AuthService>();
    final ctrl = Get.find<VpnController>();
    final theme = FTheme.of(context);
    final userName = auth.currentUser?.displayName?.split(' ').first ?? 'User';

    return FScaffold(
      header: FHeader(
        title: Text(
          'Mindsafe',
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
        suffixes: [
          if (auth.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.15),
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
            ),
        ],
      ),
      child: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Greeting ───
              Text(
                'home_greeting'.trParams({'name': userName}),
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ctrl.isRunning.value
                    ? 'home_protected'.tr
                    : 'home_not_protected'.tr,
                style: theme.typography.xs.copyWith(
                  color: ctrl.isRunning.value
                      ? const Color(0xFF22C55E)
                      : theme.colors.mutedForeground,
                ),
              ),

              const SizedBox(height: 14),

              // ─── Unified Monitoring Card ───
              _MonitoringCard(ctrl: ctrl, theme: theme),

              const SizedBox(height: 10),

              // ─── Today Stats Row ───
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (_) {
                          final today = ctrl.todayDomainCount.value;
                          final yesterday = ctrl.yesterdayDomainCount.value;
                          final diff = today - yesterday;
                          final diffText = diff > 0
                              ? '+$diff ${'home_from_yesterday'.tr}'
                              : diff < 0
                              ? '$diff ${'home_from_yesterday'.tr}'
                              : 'home_same_as_yesterday'.tr;
                          final diffColor = diff > 0
                              ? Colors.orange
                              : diff < 0
                              ? const Color(0xFF22C55E)
                              : theme.colors.mutedForeground.withValues(
                                  alpha: 0.5,
                                );
                          final diffIcon = diff > 0
                              ? Icons.trending_up
                              : diff < 0
                              ? Icons.trending_down
                              : Icons.trending_flat;
                          return _MiniStatCard(
                            icon: Icons.language,
                            label: 'home_domains'.tr,
                            value: '$today',
                            subtitle: diffText,
                            trailing: Icon(
                              diffIcon,
                              size: 12,
                              color: diffColor,
                            ),
                            subtitleColor: diffColor,
                            theme: theme,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Builder(
                        builder: (_) {
                          final todayMin = ctrl.todayDurationMinutes.value;
                          final yesterdayMin =
                              ctrl.yesterdayDurationMinutes.value;
                          final diff = todayMin - yesterdayMin;
                          final diffText = diff > 0
                              ? '+${_formatDuration(diff)} ${'home_from_yesterday'.tr}'
                              : diff < 0
                              ? '-${_formatDuration(diff.abs())} ${'home_from_yesterday'.tr}'
                              : 'home_same_as_yesterday'.tr;
                          final diffColor = diff > 0
                              ? Colors.orange
                              : diff < 0
                              ? const Color(0xFF22C55E)
                              : theme.colors.mutedForeground.withValues(
                                  alpha: 0.5,
                                );
                          final diffIcon = diff > 0
                              ? Icons.trending_up
                              : diff < 0
                              ? Icons.trending_down
                              : Icons.trending_flat;
                          return _MiniStatCard(
                            icon: Icons.access_time_rounded,
                            label: 'home_duration'.tr,
                            value: _formatDuration(todayMin),
                            subtitle: diffText,
                            trailing: Icon(
                              diffIcon,
                              size: 12,
                              color: diffColor,
                            ),
                            subtitleColor: diffColor,
                            theme: theme,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ─── Weekly Summary with Sparkline ───
              _WeeklyCard(ctrl: ctrl, theme: theme),

              const SizedBox(height: 10),

              // ─── Insight Card ───
              _InsightCard(ctrl: ctrl, theme: theme),

              const SizedBox(height: 10),

              // ─── Top Domains Today ───
              if (ctrl.todayTopDomains.isNotEmpty)
                _TopDomainsCard(ctrl: ctrl, theme: theme),

              if (ctrl.todayTopDomains.isNotEmpty) const SizedBox(height: 10),

              // ─── Category Breakdown ───
              if (ctrl.todayCategoryBreakdown.isNotEmpty)
                _CategoryBreakdownCard(ctrl: ctrl, theme: theme),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Unified Monitoring Card ──────────────────────────────────

class _MonitoringCard extends StatelessWidget {
  final VpnController ctrl;
  final FThemeData theme;

  const _MonitoringCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final vpnActive = ctrl.isRunning.value;
      final a11yActive = ctrl.isAccessibilityEnabled.value;
      final notifActive = ctrl.isNotificationEnabled.value;
      final allActive = vpnActive && a11yActive && notifActive;
      final someActive = vpnActive || a11yActive;

      final statusColor = allActive
          ? const Color(0xFF22C55E)
          : someActive
          ? Colors.orange
          : theme.colors.mutedForeground;

      final statusText = allActive
          ? 'home_monitoring_all_active'.tr
          : someActive
          ? 'home_monitoring_partial'.tr
          : 'home_monitoring_inactive'.tr;

      return GestureDetector(
        onTap: () => _showMonitoringSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: allActive
                ? LinearGradient(
                    colors: [
                      const Color(0xFF22C55E).withValues(alpha: 0.12),
                      const Color(0xFF22C55E).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : someActive
                ? LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.08),
                      Colors.orange.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: allActive
                  ? const Color(0xFF22C55E).withValues(alpha: 0.35)
                  : someActive
                  ? Colors.orange.withValues(alpha: 0.3)
                  : theme.colors.border,
            ),
            color: (allActive || someActive) ? null : theme.colors.background,
          ),
          child: Row(
            children: [
              // Shield icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  allActive
                      ? Icons.shield
                      : someActive
                      ? Icons.shield
                      : Icons.shield_outlined,
                  size: 24,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _statusDot(vpnActive),
                        const SizedBox(width: 4),
                        Text(
                          'VPN',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusDot(a11yActive),
                        const SizedBox(width: 4),
                        Text(
                          'URL Capture',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusDot(notifActive),
                        const SizedBox(width: 4),
                        Text(
                          'home_notification'.tr,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: theme.colors.mutedForeground.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statusDot(bool active) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF22C55E) : Colors.grey,
      ),
    );
  }

  void _showMonitoringSheet(BuildContext context) {
    // Refresh accessibility + notification status before opening so the sheet
    // always reflects the current state (user may have just toggled them in
    // Android Settings without returning to the app via a lifecycle event).
    ctrl.refreshMonitoringStatus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MonitoringSheet(ctrl: ctrl, theme: theme),
    );
  }
}

// ─── Monitoring Bottom Sheet ──────────────────────────────────

class _MonitoringSheet extends StatelessWidget {
  final VpnController ctrl;
  final FThemeData theme;

  const _MonitoringSheet({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: theme.colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Obx(() {
            final vpnActive = ctrl.isRunning.value;
            final a11yActive = ctrl.isAccessibilityEnabled.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colors.mutedForeground.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'home_monitoring_title'.tr,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'home_monitoring_subtitle'.tr,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // VPN Toggle
                _MonitoringToggle(
                  icon: Icons.vpn_key_rounded,
                  iconColor: vpnActive
                      ? const Color(0xFF22C55E)
                      : theme.colors.mutedForeground,
                  title: 'home_vpn_service'.tr,
                  description: 'home_vpn_desc'.tr,
                  active: vpnActive,
                  theme: theme,
                  onTap: () async {
                    if (vpnActive) {
                      await ctrl.stopVpn();
                      if (context.mounted) {
                        showFToast(
                          context: context,
                          style: const FToastStyleDelta.delta(
                            constraints: BoxConstraints(
                              minWidth: double.infinity,
                              maxWidth: double.infinity,
                            ),
                          ),
                          alignment: FToastAlignment.topCenter,
                          icon: const Icon(Icons.shield_outlined),
                          title: Text('toast_monitoring_stopped'.tr),
                          description: Text('toast_monitoring_stopped_desc'.tr),
                        );
                      }
                    } else {
                      final result = await ctrl.startVpn();
                      if (!context.mounted) return;
                      if (result == 'started') {
                        showFToast(
                          context: context,
                          style: const FToastStyleDelta.delta(
                            constraints: BoxConstraints(
                              minWidth: double.infinity,
                              maxWidth: double.infinity,
                            ),
                          ),
                          alignment: FToastAlignment.topCenter,
                          icon: const Icon(
                            Icons.shield,
                            color: Color(0xFF22C55E),
                          ),
                          title: Text('toast_monitoring_started'.tr),
                          description: Text('toast_monitoring_started_desc'.tr),
                        );
                      }
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Accessibility Toggle
                _MonitoringToggle(
                  icon: Icons.accessibility_new_rounded,
                  iconColor: a11yActive
                      ? const Color(0xFF22C55E)
                      : theme.colors.mutedForeground,
                  title: 'home_url_capture'.tr,
                  description: 'home_url_capture_desc'.tr,
                  active: a11yActive,
                  theme: theme,
                  onTap: () {
                    ctrl.openAccessibilitySettings();
                  },
                ),

                const SizedBox(height: 12),

                // Notification Toggle
                _MonitoringToggle(
                  icon: Icons.notifications_active_rounded,
                  iconColor: ctrl.isNotificationEnabled.value
                      ? const Color(0xFF22C55E)
                      : theme.colors.mutedForeground,
                  title: 'home_notification'.tr,
                  description: 'home_notification_desc'.tr,
                  active: ctrl.isNotificationEnabled.value,
                  theme: theme,
                  onTap: () async {
                    final newValue = !ctrl.isNotificationEnabled.value;

                    // If enabling, check & request OS permission first
                    if (newValue) {
                      try {
                        final notifService = Get.find<NotificationService>();
                        final allowed = await notifService
                            .areNotificationsAllowed();
                        if (!allowed) {
                          // Request permission from OS
                          final granted = await notifService
                              .requestPermission();
                          if (!granted) {
                            // Permission denied - show toast and don't enable
                            if (context.mounted) {
                              showFToast(
                                context: context,
                                style: const FToastStyleDelta.delta(
                                  constraints: BoxConstraints(
                                    minWidth: double.infinity,
                                    maxWidth: double.infinity,
                                  ),
                                ),
                                alignment: FToastAlignment.topCenter,
                                icon: const Icon(
                                  Icons.notifications_off_outlined,
                                  color: Colors.red,
                                ),
                                title: Text('toast_notif_denied'.tr),
                                description: Text('toast_notif_denied_desc'.tr),
                              );
                            }
                            return; // Don't toggle on
                          }
                        }
                      } catch (e) {
                        debugPrint('❌ Permission check error: $e');
                      }
                    }

                    ctrl.setNotificationEnabled(newValue);
                    if (context.mounted) {
                      showFToast(
                        context: context,
                        style: const FToastStyleDelta.delta(
                          constraints: BoxConstraints(
                            minWidth: double.infinity,
                            maxWidth: double.infinity,
                          ),
                        ),
                        alignment: FToastAlignment.topCenter,
                        icon: Icon(
                          newValue
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: newValue ? const Color(0xFF22C55E) : null,
                        ),
                        title: Text(
                          newValue
                              ? 'toast_notif_enabled'.tr
                              : 'toast_notif_disabled'.tr,
                        ),
                        description: Text(
                          newValue
                              ? 'toast_notif_enabled_desc'.tr
                              : 'toast_notif_disabled_desc'.tr,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 8),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Monitoring Toggle Row ────────────────────────────────────

class _MonitoringToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool active;
  final FThemeData theme;
  final VoidCallback onTap;

  const _MonitoringToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.active,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = active
        ? const Color(0xFF22C55E)
        : theme.colors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : theme.colors.border,
        ),
        color: active ? const Color(0xFF22C55E).withValues(alpha: 0.05) : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          // Title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: statusColor.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        active ? 'home_active'.tr : 'home_inactive'.tr,
                        style: theme.typography.xs.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Toggle icon button
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? Colors.red.withValues(alpha: 0.12)
                    : const Color(0xFF22C55E).withValues(alpha: 0.12),
              ),
              child: Icon(
                active ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: active ? Colors.red : const Color(0xFF22C55E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat Card ───────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Widget? trailing;
  final Color? subtitleColor;
  final FThemeData theme;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.subtitle,
    this.trailing,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colors.mutedForeground.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.typography.xl.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (trailing != null) ...[trailing!, const SizedBox(width: 3)],
                Flexible(
                  child: Text(
                    subtitle!,
                    style: theme.typography.xs.copyWith(
                      fontSize: 10,
                      color:
                          subtitleColor ??
                          theme.colors.mutedForeground.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Weekly Card with Sparkline ───────────────────────────────

class _WeeklyCard extends StatelessWidget {
  final VpnController ctrl;
  final FThemeData theme;

  const _WeeklyCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final counts = ctrl.weeklyDailyCounts;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.8)),
        gradient: LinearGradient(
          colors: [
            theme.colors.primary.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'home_weekly_summary'.tr,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              Text(
                'home_last_7_days'.tr,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Sparkline
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _SparklinePainter(
                data: counts.toList(),
                lineColor: theme.colors.primary,
                fillColor: theme.colors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _dayLabels(theme),
          ),
          const SizedBox(height: 10),
          // Total duration
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                '${'home_weekly_duration'.tr}: ${_formatDuration(ctrl.weeklyTotalMinutes.value)}',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _dayLabels(FThemeData theme) {
    final now = DateTime.now();
    final days = <String>[];
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      days.add(
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1],
      );
    }
    return days
        .map(
          (d) => Text(
            d,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontSize: 9,
            ),
          ),
        )
        .toList();
  }
}

// ─── Sparkline Painter ────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max).toDouble().clamp(1, double.infinity);
    final stepX = size.width / (data.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxVal * size.height * 0.85);
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Dot on last point
    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(points.last, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

// ─── Insight Card ─────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final VpnController ctrl;
  final FThemeData theme;

  const _InsightCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final today = ctrl.todayDomainCount.value;
    final yesterday = ctrl.yesterdayDomainCount.value;

    String text;
    IconData icon;
    Color color;

    if (today == 0 && yesterday == 0) {
      text = 'home_insight_new'.tr;
      icon = Icons.lightbulb_outline;
      color = theme.colors.mutedForeground;
    } else if (today > yesterday) {
      text = 'home_insight_up'.tr;
      icon = Icons.trending_up;
      color = const Color(0xFFF59E0B); // amber
    } else if (today < yesterday) {
      text = 'home_insight_down'.tr;
      icon = Icons.trending_down;
      color = const Color(0xFF22C55E); // green
    } else {
      text = 'home_insight_stable'.tr;
      icon = Icons.trending_flat;
      color = const Color(0xFF3B82F6); // blue
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home_insight'.tr,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Domains Card ─────────────────────────────────────────

class _TopDomainsCard extends StatelessWidget {
  final VpnController ctrl;
  final FThemeData theme;

  const _TopDomainsCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final domains = ctrl.todayTopDomains;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, size: 16, color: theme.colors.primary),
              const SizedBox(width: 8),
              Text(
                'home_top_domains'.tr,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              const Spacer(),
              Text(
                'home_today'.tr,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...domains.asMap().entries.map((entry) {
            final idx = entry.key;
            final domain = entry.value.key;
            final count = entry.value.value;
            final maxCount = domains.first.value;
            final fraction = maxCount > 0 ? count / maxCount : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: idx < domains.length - 1 ? 8 : 0,
              ),
              child: Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${idx + 1}',
                      style: theme.typography.xs.copyWith(
                        fontWeight: FontWeight.w700,
                        color: idx < 3
                            ? theme.colors.primary
                            : theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  // Domain name + bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.foreground,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 3,
                            backgroundColor: theme.colors.mutedForeground
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Visit count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: theme.colors.mutedForeground.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: theme.typography.xs.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Category Breakdown Card ──────────────────────────────────

const _categoryMeta = <String, ({IconData icon, Color color, String label})>{
  'safe': (
    icon: Icons.check_circle_outline,
    color: Color(0xFF22C55E),
    label: 'Safe',
  ),
  'adult': (icon: Icons.block, color: Color(0xFFEF4444), label: 'Adult'),
  'gambling': (icon: Icons.casino, color: Color(0xFFF59E0B), label: 'Gambling'),
  'phishing': (
    icon: Icons.phishing,
    color: Color(0xFFEC4899),
    label: 'Phishing',
  ),
  'malware': (
    icon: Icons.bug_report,
    color: Color(0xFFDC2626),
    label: 'Malware',
  ),
  'drugs': (icon: Icons.medication, color: Color(0xFF8B5CF6), label: 'Drugs'),
  'dating': (icon: Icons.favorite, color: Color(0xFFF472B6), label: 'Dating'),
  'hacking': (icon: Icons.terminal, color: Color(0xFF64748B), label: 'Hacking'),
  'dangerous': (
    icon: Icons.warning_amber,
    color: Color(0xFFEA580C),
    label: 'Dangerous',
  ),
  'warez': (icon: Icons.download, color: Color(0xFF6366F1), label: 'Warez'),
  'cryptojacking': (
    icon: Icons.currency_bitcoin,
    color: Color(0xFFEAB308),
    label: 'Cryptojacking',
  ),
  'ddos': (icon: Icons.cloud_off, color: Color(0xFF94A3B8), label: 'DDoS'),
};

class _CategoryBreakdownCard extends StatelessWidget {
  final VpnController ctrl;
  final FThemeData theme;

  const _CategoryBreakdownCard({required this.ctrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final categories = ctrl.todayCategoryBreakdown;
    final total = categories.fold<int>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 16,
                color: theme.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'home_category_breakdown'.tr,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stacked horizontal bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: categories.map((entry) {
                  final meta = _categoryMeta[entry.key];
                  final fraction = total > 0 ? entry.value / total : 0.0;
                  return Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: Container(
                      color: meta?.color ?? theme.colors.mutedForeground,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: categories.map((entry) {
              final meta = _categoryMeta[entry.key];
              final pct = total > 0 ? (entry.value / total * 100).round() : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: meta?.color ?? theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meta?.label ?? entry.key} $pct%',
                    style: theme.typography.xs.copyWith(
                      fontSize: 10,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
