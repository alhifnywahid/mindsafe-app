import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';
import 'package:mindsafe_flutter/core/widgets/app_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final db = Get.find<LocalDatabase>();
    final userId = Get.find<AuthService>().currentUser?.uid ?? '';

    return FScaffold(
      header: FHeader(
        title: Text(
          'insights_title'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: ValueListenableBuilder(
        valueListenable: db.domainAccess.listenable(),
        builder: (context, Box<DomainAccess> box, _) {
          final accesses = db.userDomainAccess(userId);

          if (accesses.isEmpty) {
            return Align(
              alignment: const FractionalOffset(0.5, 0.42),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with subtle glow
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.colors.primary.withValues(alpha: 0.12),
                            theme.colors.primary.withValues(alpha: 0.03),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 36,
                        color: theme.colors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'insights_empty'.tr,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'insights_empty_desc'.tr,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radio_button_on,
                          size: 8,
                          color: const Color(0xFF22C55E).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'insights_monitoring_active'.tr,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final insights = _generateInsights(accesses);

          if (insights.isEmpty) {
            return Align(
              alignment: const FractionalOffset(0.5, 0.42),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with green glow
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF22C55E).withValues(alpha: 0.15),
                            const Color(0xFF22C55E).withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        size: 36,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'insights_clean'.tr,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'insights_clean_desc'.tr,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radio_button_on,
                          size: 8,
                          color: const Color(0xFF22C55E).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'insights_monitoring_active'.tr,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TapScaleWrapper(
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                insight.color.withValues(alpha: 0.20),
                                insight.color.withValues(alpha: 0.08),
                              ],
                              center: Alignment.topLeft,
                              radius: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: insight.color.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            insight.icon,
                            color: insight.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      insight.title,
                                      style: theme.typography.base.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colors.foreground,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (insight.badge != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: insight.color.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        insight.badge!,
                                        style: theme.typography.xs.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: insight.color.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                insight.description,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_Insight> _generateInsights(List<dynamic> accesses) {
    final insights = <_Insight>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ── Time ranges ──
    final weekAgo = today.subtract(const Duration(days: 7));
    final twoWeeksAgo = today.subtract(const Duration(days: 14));
    final monthAgo = today.subtract(const Duration(days: 30));

    final todayAccesses = accesses
        .where((a) => a.timestamp.isAfter(today))
        .toList();
    final weekAccesses = accesses
        .where((a) => a.timestamp.isAfter(weekAgo))
        .toList();
    final prevWeekAccesses = accesses
        .where(
          (a) =>
              a.timestamp.isAfter(twoWeeksAgo) && a.timestamp.isBefore(weekAgo),
        )
        .toList();
    final monthAccesses = accesses
        .where((a) => a.timestamp.isAfter(monthAgo))
        .toList();

    final uniqueDomains = todayAccesses.map((a) => a.domain).toSet();

    final categories = <String, int>{};
    for (final access in todayAccesses) {
      categories[access.category] = (categories[access.category] ?? 0) + 1;
    }

    final totalSeconds = todayAccesses.fold<int>(
      0,
      (sum, a) => sum + (a.durationSeconds as int),
    );

    // ═══════════════ TODAY INSIGHTS ═══════════════

    // High activity
    if (uniqueDomains.length > 20) {
      insights.add(
        _Insight(
          title: 'insights_high_activity'.tr,
          description: 'insights_high_activity_desc'.trParams({
            'count': '${uniqueDomains.length}',
          }),
          icon: Icons.trending_up,
          color: Colors.orange,
          badge: 'insights_badge_today'.tr,
        ),
      );
    }

    // Adult content
    final adultCount = categories['adult'] ?? 0;
    if (adultCount > 0) {
      insights.add(
        _Insight(
          title: 'insights_adult_detected'.tr,
          description: 'insights_adult_desc'.trParams({'count': '$adultCount'}),
          icon: Icons.warning_rounded,
          color: Colors.red,
          badge: 'insights_badge_today'.tr,
        ),
      );
    }

    // Clean browsing
    if (adultCount == 0 && todayAccesses.isNotEmpty) {
      insights.add(
        _Insight(
          title: 'insights_clean'.tr,
          description: 'insights_clean_desc'.tr,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          badge: 'insights_badge_today'.tr,
        ),
      );
    }

    // Extended usage
    if (totalSeconds > 3600) {
      final mins = (totalSeconds / 60).round();
      insights.add(
        _Insight(
          title: 'insights_extended_usage'.tr,
          description: 'insights_extended_desc'.trParams({'mins': '$mins'}),
          icon: Icons.timer,
          color: Colors.blue,
          badge: 'insights_badge_today'.tr,
        ),
      );
    }

    // Low activity
    if (uniqueDomains.length <= 5 && todayAccesses.isNotEmpty) {
      insights.add(
        _Insight(
          title: 'insights_low_activity'.tr,
          description: 'insights_low_activity_desc'.trParams({
            'count': '${uniqueDomains.length}',
          }),
          icon: Icons.summarize,
          color: Colors.teal,
          badge: 'insights_badge_today'.tr,
        ),
      );
    }

    // ═══════════════ WEEKLY INSIGHTS ═══════════════

    if (weekAccesses.isNotEmpty) {
      final weekDomains = weekAccesses.map((a) => a.domain).toSet();

      // Weekly trend vs previous week
      if (prevWeekAccesses.isNotEmpty) {
        final thisWeekCount = weekAccesses.length;
        final prevWeekCount = prevWeekAccesses.length;
        final diff = thisWeekCount - prevWeekCount;
        final pct = prevWeekCount > 0
            ? ((diff / prevWeekCount) * 100).round().abs()
            : 0;

        if (diff > 0 && pct >= 10) {
          insights.add(
            _Insight(
              title: 'insights_weekly_trend_up'.tr,
              description: 'insights_weekly_trend_up_desc'.trParams({
                'pct': '$pct',
              }),
              icon: Icons.trending_up,
              color: Colors.orange,
              badge: 'insights_badge_weekly'.tr,
            ),
          );
        } else if (diff < 0 && pct >= 10) {
          insights.add(
            _Insight(
              title: 'insights_weekly_trend_down'.tr,
              description: 'insights_weekly_trend_down_desc'.trParams({
                'pct': '$pct',
              }),
              icon: Icons.trending_down,
              color: Colors.green,
              badge: 'insights_badge_weekly'.tr,
            ),
          );
        }
      }

      // Daily average this week
      final avgDomainsPerDay = (weekDomains.length / 7).ceil();
      if (avgDomainsPerDay > 0) {
        insights.add(
          _Insight(
            title: 'insights_weekly_avg'.tr,
            description: 'insights_weekly_avg_desc'.trParams({
              'avg': '$avgDomainsPerDay',
            }),
            icon: Icons.bar_chart_rounded,
            color: Colors.indigo,
            badge: 'insights_badge_weekly'.tr,
          ),
        );
      }

      // Today vs weekly average
      if (uniqueDomains.isNotEmpty) {
        final todayCount = uniqueDomains.length;
        if (todayCount > avgDomainsPerDay * 1.5 && avgDomainsPerDay > 0) {
          insights.add(
            _Insight(
              title: 'insights_above_avg'.tr,
              description: 'insights_above_avg_desc'.trParams({
                'today': '$todayCount',
                'avg': '$avgDomainsPerDay',
              }),
              icon: Icons.arrow_upward_rounded,
              color: Colors.deepOrange,
              badge: 'insights_badge_today'.tr,
            ),
          );
        } else if (todayCount < avgDomainsPerDay * 0.5 &&
            avgDomainsPerDay > 2) {
          insights.add(
            _Insight(
              title: 'insights_below_avg'.tr,
              description: 'insights_below_avg_desc'.trParams({
                'today': '$todayCount',
                'avg': '$avgDomainsPerDay',
              }),
              icon: Icons.arrow_downward_rounded,
              color: Colors.teal,
              badge: 'insights_badge_today'.tr,
            ),
          );
        }
      }

      // Most active day
      final dayBuckets = <int, int>{};
      for (final a in weekAccesses) {
        final weekday = a.timestamp.weekday;
        dayBuckets[weekday] = (dayBuckets[weekday] ?? 0) + 1;
      }
      if (dayBuckets.isNotEmpty) {
        final maxDay = dayBuckets.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        final dayNames = [
          'insights_day_mon'.tr,
          'insights_day_tue'.tr,
          'insights_day_wed'.tr,
          'insights_day_thu'.tr,
          'insights_day_fri'.tr,
          'insights_day_sat'.tr,
          'insights_day_sun'.tr,
        ];
        insights.add(
          _Insight(
            title: 'insights_most_active_day'.tr,
            description: 'insights_most_active_day_desc'.trParams({
              'day': dayNames[maxDay - 1],
            }),
            icon: Icons.calendar_today_rounded,
            color: Colors.purple,
            badge: 'insights_badge_weekly'.tr,
          ),
        );
      }
    }

    // ═══════════════ MONTHLY INSIGHTS ═══════════════

    if (monthAccesses.length > 7) {
      final monthDomains = monthAccesses.map((a) => a.domain).toSet();

      // Monthly domain summary
      insights.add(
        _Insight(
          title: 'insights_monthly_domains'.tr,
          description: 'insights_monthly_domains_desc'.trParams({
            'count': '${monthDomains.length}',
            'visits': '${monthAccesses.length}',
          }),
          icon: Icons.language_rounded,
          color: Colors.cyan,
          badge: 'insights_badge_monthly'.tr,
        ),
      );

      // Monthly duration
      final monthSeconds = monthAccesses.fold<int>(
        0,
        (sum, a) => sum + (a.durationSeconds as int),
      );
      final monthHours = (monthSeconds / 3600).round();
      if (monthHours >= 1) {
        insights.add(
          _Insight(
            title: 'insights_monthly_duration'.tr,
            description: 'insights_monthly_duration_desc'.trParams({
              'hours': '$monthHours',
            }),
            icon: Icons.schedule_rounded,
            color: Colors.blueGrey,
            badge: 'insights_badge_monthly'.tr,
          ),
        );
      }
    }

    return insights;
  }
}

class _Insight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? badge;

  const _Insight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.badge,
  });
}

// ─── Tap Scale Wrapper ────────────────────────────────────────

class _TapScaleWrapper extends StatefulWidget {
  final Widget child;
  const _TapScaleWrapper({required this.child});

  @override
  State<_TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<_TapScaleWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
