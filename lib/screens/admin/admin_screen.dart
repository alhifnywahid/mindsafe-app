import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/data/services/domain_classifier.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/models/domain_rule.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';
import 'package:mindsafe_flutter/core/widgets/app_card.dart';
import 'package:mindsafe_flutter/core/widgets/app_bottom_sheet.dart';

// ─── Admin Dashboard Screen ───
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FScaffold(
      header: FHeader(
        title: Text(
          'admin_dashboard'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: _DashboardTab(),
    );
  }
}

// ─── Admin Rules Screen ───
class AdminRulesScreen extends StatelessWidget {
  const AdminRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FScaffold(
      header: FHeader(
        title: Text(
          'admin_rules'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: _DomainRulesTab(),
    );
  }
}

// ─── Admin Audit Screen ───
class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FScaffold(
      header: FHeader(
        title: Text(
          'admin_audit'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: _AuditLogTab(),
    );
  }
}

// ─── Admin Notification Screen ───
class AdminNotificationScreen extends StatelessWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FScaffold(
      header: FHeader(
        title: Text(
          'admin_notif'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: _NotificationTab(),
    );
  }
}

// ─── Dashboard Tab ───
class _DashboardTab extends StatefulWidget {
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic> _adminStats = {'userCount': 0, 'status': 'unknown'};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final firestoreRepo = Get.find<FirestoreRepository>();
    final stats = await firestoreRepo.getAdminStats();
    if (mounted) {
      setState(() {
        _adminStats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final db = Get.find<LocalDatabase>();
    final classifier = Get.find<DomainClassifier>();
    final allAccess = db.domainAccess.values.toList();

    // ── Compute stats ──
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayAccess = allAccess
        .where((a) => a.timestamp.isAfter(todayStart))
        .toList();
    final totalAccessToday = todayAccess.length;
    final totalSecondsToday = todayAccess.fold<int>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );
    final totalHoursToday = (totalSecondsToday / 3600).toStringAsFixed(1);

    // Category breakdown
    final categoryMap = <String, int>{};
    for (final a in allAccess) {
      categoryMap[a.category] = (categoryMap[a.category] ?? 0) + 1;
    }
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalEntries = allAccess.length;

    // Recent 10 entries
    final recentAccess = List.of(allAccess)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent10 = recentAccess.take(10).toList();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat Cards Grid ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.80,
                children: [
                  _GradientStatCard(
                    icon: Icons.people_alt_rounded,
                    label: 'admin_total_users'.tr,
                    value: '${_adminStats['userCount']}',
                    gradient: const [Color(0xFF3730A3), Color(0xFF4338CA)],
                  ),
                  _GradientStatCard(
                    icon: Icons.cloud_done_rounded,
                    label: 'admin_system_status'.tr,
                    value: _adminStats['status'] == 'healthy'
                        ? 'admin_healthy'.tr
                        : '⚠️',
                    gradient: _adminStats['status'] == 'healthy'
                        ? const [Color(0xFF047857), Color(0xFF059669)]
                        : const [Color(0xFFB45309), Color(0xFFD97706)],
                  ),
                  _GradientStatCard(
                    icon: Icons.dns_rounded,
                    label: 'admin_total_domains'.tr,
                    value: '${classifier.totalDomains.value}',
                    gradient: const [Color(0xFF9A3412), Color(0xFFC2410C)],
                  ),
                  _GradientStatCard(
                    icon: Icons.rule_rounded,
                    label: 'admin_total_rules'.tr,
                    value: '${db.domainRules.length}',
                    gradient: const [Color(0xFF155E75), Color(0xFF0E7490)],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Today's Activity ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('admin_today_activity'.tr, theme),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ActivityMiniCard(
                          icon: Icons.touch_app_rounded,
                          value: '$totalAccessToday',
                          label: 'admin_accesses'.tr,
                          color: const Color(0xFF6366F1),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActivityMiniCard(
                          icon: Icons.schedule_rounded,
                          value: '$totalHoursToday h',
                          label: 'admin_hours'.tr,
                          color: const Color(0xFF10B981),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Category Breakdown ──
                  _SectionLabel('admin_category_breakdown'.tr, theme),
                  const SizedBox(height: 8),
                  if (sortedCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'admin_no_data'.tr,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: sortedCategories.map((entry) {
                          final pct = totalEntries > 0
                              ? entry.value / totalEntries
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _categoryColor(entry.key, theme),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'category_${entry.key}'.tr,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.foreground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${entry.value}',
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.foreground,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 6,
                                      backgroundColor: theme.colors.border,
                                      valueColor: AlwaysStoppedAnimation(
                                        _categoryColor(entry.key, theme),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${(pct * 100).toStringAsFixed(0)}%',
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // ── Recent Activity ──
                  _SectionLabel('admin_recent_activity'.tr, theme),
                  const SizedBox(height: 8),
                  if (recent10.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'admin_no_data'.tr,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: List.generate(recent10.length, (i) {
                          final a = recent10[i];
                          final time =
                              '${a.timestamp.hour.toString().padLeft(2, '0')}:${a.timestamp.minute.toString().padLeft(2, '0')}';
                          final date =
                              '${a.timestamp.day}/${a.timestamp.month}/${a.timestamp.year}';
                          return Column(
                            children: [
                              if (i > 0)
                                Divider(color: theme.colors.border, height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _categoryColor(
                                          a.category,
                                          theme,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.domain,
                                            style: theme.typography.sm.copyWith(
                                              color: theme.colors.foreground,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '$date  $time',
                                            style: theme.typography.xs.copyWith(
                                              color:
                                                  theme.colors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _categoryColor(
                                          a.category,
                                          theme,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'category_${a.category}'.tr,
                                        style: theme.typography.xs.copyWith(
                                          color: _categoryColor(
                                            a.category,
                                            theme,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // ── Refresh ──
                  GestureDetector(
                    onTap: () async {
                      await _loadStats();
                      setState(() {});
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'admin_refresh'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category, FThemeData theme) {
    switch (category) {
      case 'adult':
        return const Color(0xFFEF4444);
      case 'malware':
        return const Color(0xFFDC2626);
      case 'phishing':
        return const Color(0xFFB91C1C);
      case 'dangerous':
        return const Color(0xFFF87171);
      case 'gambling':
        return const Color(0xFFF97316);
      case 'drugs':
        return const Color(0xFFEA580C);
      case 'warez':
        return const Color(0xFFFB923C);
      case 'cryptojacking':
        return const Color(0xFFE11D48);
      case 'hacking':
        return const Color(0xFFBE123C);
      case 'ddos':
        return const Color(0xFFDB2777);
      case 'dating':
        return const Color(0xFFF59E0B);
      case 'safe':
        return const Color(0xFF10B981);
      default:
        return theme.colors.mutedForeground;
    }
  }
}

// ─── Gradient Stat Card ───
class _GradientStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _GradientStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Mini Card ───
class _ActivityMiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final FThemeData theme;

  const _ActivityMiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                Text(
                  label,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
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

// ─── Section Label ───
class _SectionLabel extends StatelessWidget {
  final String title;
  final FThemeData theme;

  const _SectionLabel(this.title, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
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

// ─── Domain Rules Tab ───
class _DomainRulesTab extends StatefulWidget {
  @override
  State<_DomainRulesTab> createState() => _DomainRulesTabState();
}

class _DomainRulesTabState extends State<_DomainRulesTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final db = Get.find<LocalDatabase>();

    return Column(
      children: [
        // ── Tab Selector ──
        TabBar(
          controller: _tabController,
          labelColor: theme.colors.primary,
          unselectedLabelColor: theme.colors.mutedForeground,
          indicator: const BoxDecoration(),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rule_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('admin_tab_rules'.tr),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('admin_tab_skip'.tr),
                ],
              ),
            ),
          ],
        ),

        // ── Tab Views ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildRulesTab(theme, db), _buildSkipTab(theme, db)],
          ),
        ),
      ],
    );
  }

  // ── Rules Tab Content ──
  Widget _buildRulesTab(FThemeData theme, LocalDatabase db) {
    final rules = db.domainRules.values.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showAddRuleDialog(context, db, theme),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3730A3), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3730A3).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'admin_add_rule'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rule_rounded,
                      size: 40,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'admin_no_data'.tr,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AppCard(
              child: Column(
                children: List.generate(rules.length, (i) {
                  final rule = rules[i];
                  return Column(
                    children: [
                      if (i > 0) Divider(color: theme.colors.border, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _categoryColor(rule.category, theme),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rule.pattern,
                                style: theme.typography.sm.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colors.foreground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _categoryColor(
                                  rule.category,
                                  theme,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'category_${rule.category}'.tr,
                                style: theme.typography.xs.copyWith(
                                  color: _categoryColor(rule.category, theme),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                showFSheet(
                                  context: context,
                                  side: FLayout.btt,
                                  mainAxisMaxRatio: null,
                                  builder: (ctx) => AppBottomSheet(
                                    children: [
                                      Icon(
                                        Icons.delete_rounded,
                                        size: 40,
                                        color: theme.colors.error,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'admin_confirm_delete'.tr,
                                        style: theme.typography.lg.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colors.foreground,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'admin_confirm_delete_rule_desc'
                                            .trParams({
                                              'pattern': rule.pattern,
                                            }),
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
                                              variant:
                                                  FButtonVariant.destructive,
                                              onPress: () {
                                                Navigator.pop(ctx);
                                                Get.find<DomainClassifier>()
                                                    .deleteRule(rule.id);
                                                setState(() {});
                                              },
                                              child: Text('admin_delete'.tr),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: theme.colors.error,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ── Skip Tab Content ──
  Widget _buildSkipTab(FThemeData theme, LocalDatabase db) {
    final skipDomains = db.skipDomains.values.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showAddSkipDialog(context, db, theme),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9A3412), Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9A3412).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'admin_add_skip'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (skipDomains.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 40,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'admin_no_skip_rules'.tr,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AppCard(
              child: Column(
                children: List.generate(skipDomains.length, (i) {
                  final domain = skipDomains[i];
                  return Column(
                    children: [
                      if (i > 0) Divider(color: theme.colors.border, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFC2410C,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.block_rounded,
                                color: Color(0xFFC2410C),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    domain,
                                    style: theme.typography.sm.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colors.foreground,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'admin_skip_desc'.tr,
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showFSheet(
                                  context: context,
                                  side: FLayout.btt,
                                  mainAxisMaxRatio: null,
                                  builder: (ctx) => AppBottomSheet(
                                    children: [
                                      Icon(
                                        Icons.delete_rounded,
                                        size: 40,
                                        color: theme.colors.error,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'admin_confirm_delete'.tr,
                                        style: theme.typography.lg.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colors.foreground,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'admin_confirm_delete_skip_desc'
                                            .trParams({'domain': domain}),
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
                                              variant:
                                                  FButtonVariant.destructive,
                                              onPress: () async {
                                                Navigator.pop(ctx);
                                                await Get.find<
                                                      DomainClassifier
                                                    >()
                                                    .deleteSkipDomain(domain);
                                                setState(() {});
                                              },
                                              child: Text('admin_delete'.tr),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: theme.colors.error,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(
    BuildContext context,
    LocalDatabase db,
    FThemeData theme,
  ) {
    final patternCtrl = TextEditingController();
    String selectedCategory = 'safe';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colors.background,
        title: Text(
          'admin_add_domain_rule'.tr,
          style: theme.typography.lg.copyWith(color: theme.colors.foreground),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: patternCtrl,
              style: TextStyle(color: theme.colors.foreground),
              decoration: InputDecoration(
                labelText: 'admin_domain_pattern'.tr,
                hintText: 'admin_domain_hint'.tr,
                labelStyle: TextStyle(color: theme.colors.mutedForeground),
                hintStyle: TextStyle(color: theme.colors.mutedForeground),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setLocalState) {
                return DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  dropdownColor: theme.colors.background,
                  style: TextStyle(color: theme.colors.foreground),
                  items:
                      [
                            'safe',
                            'adult',
                            'gambling',
                            'phishing',
                            'malware',
                            'cryptojacking',
                            'drugs',
                            'hacking',
                            'dangerous',
                            'dating',
                            'ddos',
                            'warez',
                          ]
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text('category_$c'.tr),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      selectedCategory = v;
                      setLocalState(() {});
                    }
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'dialog_cancel'.tr,
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () {
              if (patternCtrl.text.isNotEmpty) {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final rule = DomainRule(
                  id: id,
                  pattern: patternCtrl.text.trim(),
                  category: selectedCategory,
                  priority: 5,
                );
                final classifier = Get.find<DomainClassifier>();
                classifier.addRule(rule);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Text(
              'dialog_add'.tr,
              style: TextStyle(color: theme.colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSkipDialog(
    BuildContext context,
    LocalDatabase db,
    FThemeData theme,
  ) {
    final domainCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colors.background,
        title: Text(
          'admin_add_skip'.tr,
          style: theme.typography.lg.copyWith(color: theme.colors.foreground),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'admin_skip_explanation'.tr,
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: domainCtrl,
              style: TextStyle(color: theme.colors.foreground),
              decoration: InputDecoration(
                labelText: 'admin_skip_domain_label'.tr,
                hintText: 'admin_skip_hint'.tr,
                labelStyle: TextStyle(color: theme.colors.mutedForeground),
                hintStyle: TextStyle(color: theme.colors.mutedForeground),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'dialog_cancel'.tr,
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () async {
              final domain = domainCtrl.text.trim().toLowerCase();
              if (domain.isNotEmpty) {
                Navigator.pop(ctx);
                await Get.find<DomainClassifier>().addSkipDomain(domain);
                setState(() {});
              }
            },
            child: Text(
              'dialog_add'.tr,
              style: TextStyle(color: theme.colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category, FThemeData theme) {
    switch (category) {
      case 'adult':
      case 'malware':
      case 'phishing':
      case 'dangerous':
        return theme.colors.error;
      case 'gambling':
      case 'drugs':
      case 'warez':
        return Colors.orange;
      case 'cryptojacking':
      case 'hacking':
      case 'ddos':
        return Colors.deepOrange;
      case 'dating':
        return Colors.amber;
      case 'safe':
        return Colors.green;
      default:
        return theme.colors.mutedForeground;
    }
  }
}

// ─── Audit Log Tab ───
class _AuditLogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'admin_no_audit'.tr,
            style: theme.typography.lg.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'admin_audit_desc'.tr,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Tab ───

class _NotificationTab extends StatefulWidget {
  @override
  State<_NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<_NotificationTab> {
  List<Map<String, dynamic>> _history = [];
  bool _historyLoaded = false;

  static const _typeOptions = [
    {
      'value': 'info',
      'label': 'Informasi',
      'icon': Icons.info_outline,
      'color': Colors.blue,
    },
    {
      'value': 'update',
      'label': 'Update',
      'icon': Icons.system_update,
      'color': Colors.green,
    },
    {
      'value': 'warning',
      'label': 'Peringatan',
      'icon': Icons.warning_amber,
      'color': Colors.orange,
    },
    {
      'value': 'tip',
      'label': 'Tips',
      'icon': Icons.lightbulb_outline,
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final repo = Get.find<FirestoreRepository>();
    final data = await repo.getNotifications();
    if (mounted) {
      setState(() {
        _history = data;
        _historyLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      children: [
        // ─── Compose button ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GestureDetector(
            onTap: () => _showComposeSheet(context, theme),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colors.primary,
                    theme.colors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'admin_notif_compose'.tr,
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ─── History list ───
        Expanded(
          child: !_historyLoaded
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 56,
                        color: theme.colors.mutedForeground.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'admin_notif_empty'.tr,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notif = _history[index];
                      return _buildNotifCard(notif, theme);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif, FThemeData theme) {
    final type = notif['type'] ?? 'info';
    final typeOpt = _typeOptions.firstWhere(
      (o) => o['value'] == type,
      orElse: () => _typeOptions[0],
    );
    final sentAt = notif['sentAt'];
    String timeStr = '';
    if (sentAt != null) {
      final dt = (sentAt as dynamic).toDate() as DateTime;
      timeStr =
          '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final color = typeOpt['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeOpt['icon'] as IconData, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'] ?? '',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeOpt['label'] as String,
                        style: theme.typography.xs.copyWith(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif['body'] ?? '',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: theme.colors.mutedForeground.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        timeStr,
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _confirmDeleteNotification(
                        context,
                        notif['id'],
                        notif['title'] ?? '',
                        theme,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: theme.colors.error.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compose Bottom Sheet ───
  void _showComposeSheet(BuildContext context, FThemeData theme) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedType = 'info';
    bool isSending = false;

    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Material(
              color: Colors.transparent,
              child: AppBottomSheet(
                children: [
                  // Title
                  Text(
                    'admin_notif_compose'.tr,
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'admin_notif_compose_desc'.tr,
                    textAlign: TextAlign.center,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'admin_notif_type'.tr,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _typeOptions.map((opt) {
                      final isSelected = selectedType == opt['value'];
                      final color = opt['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(
                            () => selectedType = opt['value'] as String,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? color : theme.colors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? color
                                    : theme.colors.mutedForeground,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opt['label'] as String,
                                style: theme.typography.xs.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? color
                                      : theme.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Title field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'admin_notif_title_label'.tr,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'admin_notif_title_hint'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.colors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      hintStyle: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Body field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'admin_notif_body_label'.tr,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'admin_notif_body_hint'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.colors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      hintStyle: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Buttons
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
                          onPress: isSending
                              ? null
                              : () async {
                                  final title = titleCtrl.text.trim();
                                  final body = bodyCtrl.text.trim();
                                  if (title.isEmpty || body.isEmpty) {
                                    if (context.mounted) {
                                      showFToast(
                                        context: context,
                                        style: const FToastStyleDelta.delta(
                                          constraints: BoxConstraints(
                                            minWidth: double.infinity, maxWidth: double.infinity,
                                          ),
                                        ),
                                        alignment: FToastAlignment.topCenter,
                                        icon: const Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange,
                                        ),
                                        title: const Text('Error'),
                                        description: Text(
                                          'admin_notif_fill_all'.tr,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  setSheetState(() => isSending = true);
                                  Navigator.pop(ctx);
                                  try {
                                    final repo =
                                        Get.find<FirestoreRepository>();
                                    await repo.sendNotification(
                                      title: title,
                                      body: body,
                                      type: selectedType,
                                    );
                                    if (context.mounted) {
                                      showFToast(
                                        context: context,
                                        style: const FToastStyleDelta.delta(
                                          constraints: BoxConstraints(
                                            minWidth: double.infinity, maxWidth: double.infinity,
                                          ),
                                        ),
                                        alignment: FToastAlignment.topCenter,
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF22C55E),
                                        ),
                                        title: Text('admin_notif_sent'.tr),
                                        description: Text(title),
                                      );
                                    }
                                    _loadHistory();
                                  } catch (e) {
                                    if (context.mounted) {
                                      showFToast(
                                        context: context,
                                        style: const FToastStyleDelta.delta(
                                          constraints: BoxConstraints(
                                            minWidth: double.infinity, maxWidth: double.infinity,
                                          ),
                                        ),
                                        alignment: FToastAlignment.topCenter,
                                        icon: const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                        title: const Text('Error'),
                                        description: Text(e.toString()),
                                      );
                                    }
                                    setSheetState(() => isSending = false);
                                  }
                                },
                          prefix: isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          child: Text('admin_notif_send'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Delete confirmation ───
  void _confirmDeleteNotification(
    BuildContext context,
    String id,
    String title,
    FThemeData theme,
  ) {
    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (ctx) => AppBottomSheet(
        children: [
          Icon(Icons.delete_rounded, size: 40, color: theme.colors.error),
          const SizedBox(height: 12),
          Text(
            'admin_confirm_delete'.tr,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin_confirm_delete_notif_desc'.trParams({'title': title}),
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
                    await _deleteNotification(id);
                  },
                  child: Text('admin_delete'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final repo = Get.find<FirestoreRepository>();
      await repo.deleteNotification(id);
      _loadHistory();
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          style: const FToastStyleDelta.delta(
            constraints: BoxConstraints(minWidth: double.infinity, maxWidth: double.infinity),
          ),
          alignment: FToastAlignment.topCenter,
          icon: const Icon(Icons.error_outline, color: Colors.red),
          title: const Text('Error'),
          description: Text(e.toString()),
        );
      }
    }
  }
}
