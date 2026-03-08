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
  Map<String, dynamic> _adminStats = {'userCount': 0};
  Map<String, dynamic> _allUserStats = {
    'categoryBreakdown': <Map<String, dynamic>>[],
    'domainList': <Map<String, dynamic>>[],
    'totalEntries': 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final repo = Get.find<FirestoreRepository>();
    final results = await Future.wait([
      repo.getAdminStats(),
      repo.getAllUsersDomainStats(),
    ]);
    if (mounted) {
      setState(() {
        _adminStats = results[0];
        _allUserStats = results[1];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final classifier = Get.find<DomainClassifier>();

    // Parse all-user data
    final categoryBreakdown =
        (_allUserStats['categoryBreakdown'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final domainList =
        (_allUserStats['domainList'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final totalEntries = (_allUserStats['totalEntries'] as int?) ?? 0;

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
                    icon: Icons.dns_rounded,
                    label: 'admin_total_domains'.tr,
                    value: '${classifier.totalDomains.value}',
                    gradient: const [Color(0xFF9A3412), Color(0xFFC2410C)],
                  ),
                  Obx(
                    () => _GradientStatCard(
                      icon: Icons.rule_rounded,
                      label: 'admin_total_rules'.tr,
                      value: '${classifier.rulesCount.value}',
                      gradient: const [Color(0xFF155E75), Color(0xFF0E7490)],
                    ),
                  ),
                  Obx(
                    () => _GradientStatCard(
                      icon: Icons.block_rounded,
                      label: 'admin_total_skip'.tr,
                      value: '${classifier.skipDomainsCount.value}',
                      gradient: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Category Breakdown (All Users) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SectionLabel('admin_category_breakdown'.tr, theme),
                      const Spacer(),
                      if (totalEntries > 0)
                        Text(
                          '$totalEntries ${'admin_accesses'.tr.toLowerCase()}',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (categoryBreakdown.isEmpty)
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
                        children: List.generate(categoryBreakdown.length, (i) {
                          final entry = categoryBreakdown[i];
                          final cat = entry['category'] as String? ?? 'safe';
                          final visits = (entry['visits'] as int?) ?? 0;
                          final pct = totalEntries > 0
                              ? visits / totalEntries
                              : 0.0;
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
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _categoryColor(cat, theme),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'category_$cat'.tr,
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.foreground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$visits',
                                      style: theme.typography.sm.copyWith(
                                        color: theme.colors.foreground,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 72,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 6,
                                          backgroundColor: theme.colors.border,
                                          valueColor: AlwaysStoppedAnimation(
                                            _categoryColor(cat, theme),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 34,
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
                              ),
                            ],
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // ── Domain List (All Users, sorted by duration) ──
                  _SectionLabel('admin_all_domains'.tr, theme),
                  const SizedBox(height: 8),
                  if (domainList.isEmpty)
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
                        children: List.generate(domainList.length, (i) {
                          final d = domainList[i];
                          final domain = d['domain'] as String? ?? '';
                          final visits = (d['visits'] as int?) ?? 0;
                          final durSec = (d['durationSeconds'] as int?) ?? 0;
                          final cat = d['category'] as String? ?? 'safe';
                          final dur = _formatDuration(durSec);
                          return Column(
                            children: [
                              if (i > 0)
                                Divider(color: theme.colors.border, height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _categoryColor(cat, theme),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        domain,
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.foreground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          dur,
                                          style: theme.typography.xs.copyWith(
                                            color: theme.colors.foreground,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$visits ${'admin_visits'.tr}',
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
                            ],
                          );
                        }),
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

  String _formatDuration(int seconds) {
    if (seconds >= 86400) {
      final d = seconds ~/ 86400;
      return '$d ${'duration_days'.tr}';
    }
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      return '$h ${'duration_hours'.tr}';
    }
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      return '$m ${'duration_minutes'.tr}';
    }
    return '$seconds ${'duration_seconds'.tr}';
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

    return Stack(
      children: [
        Column(
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
        ),

        // ── FAB (changes per active tab) ──
        Positioned(
          right: 16,
          bottom: 24,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final isRulesTab = _tabController.index == 0;
              return FloatingActionButton(
                heroTag: 'rules_fab',
                onPressed: () => isRulesTab
                    ? _showAddRuleDialog(context, db, theme)
                    : _showAddSkipDialog(context, db, theme),
                backgroundColor: isRulesTab
                    ? const Color(0xFF4338CA)
                    : const Color(0xFFC2410C),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Rules Tab Content ──
  Widget _buildRulesTab(FThemeData theme, LocalDatabase db) {
    final rules = db.domainRules.values.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    const categories = [
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
    ];

    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AppBottomSheet(
          children: [
            Text(
              'admin_add_domain_rule'.tr,
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: patternCtrl,
                autofocus: true,
                style: TextStyle(color: theme.colors.foreground),
                decoration: InputDecoration(
                  labelText: 'admin_domain_pattern'.tr,
                  hintText: 'admin_domain_hint'.tr,
                  labelStyle: TextStyle(color: theme.colors.mutedForeground),
                  hintStyle: TextStyle(color: theme.colors.mutedForeground),
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
                  filled: true,
                  fillColor: theme.colors.muted.withValues(alpha: 0.15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'admin_select_category'.tr,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                final catColor = _categoryColor(cat, theme);
                return GestureDetector(
                  onTap: () => setSheetState(() => selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withValues(alpha: 0.18)
                          : theme.colors.muted.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? catColor : theme.colors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      'category_$cat'.tr,
                      style: theme.typography.xs.copyWith(
                        color: isSelected
                            ? catColor
                            : theme.colors.mutedForeground,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                    onPress: () {
                      if (patternCtrl.text.isNotEmpty) {
                        final id = DateTime.now().millisecondsSinceEpoch
                            .toString();
                        final rule = DomainRule(
                          id: id,
                          pattern: patternCtrl.text.trim(),
                          category: selectedCategory,
                          priority: 5,
                        );
                        Get.find<DomainClassifier>().addRule(rule);
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                    child: Text('dialog_add'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSkipDialog(
    BuildContext context,
    LocalDatabase db,
    FThemeData theme,
  ) {
    final domainCtrl = TextEditingController();

    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (ctx) => AppBottomSheet(
        children: [
          Text(
            'admin_add_skip'.tr,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin_skip_explanation'.tr,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: TextField(
              controller: domainCtrl,
              autofocus: true,
              style: TextStyle(color: theme.colors.foreground),
              decoration: InputDecoration(
                labelText: 'admin_skip_domain_label'.tr,
                hintText: 'admin_skip_hint'.tr,
                labelStyle: TextStyle(color: theme.colors.mutedForeground),
                hintStyle: TextStyle(color: theme.colors.mutedForeground),
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
                filled: true,
                fillColor: theme.colors.muted.withValues(alpha: 0.15),
              ),
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
                  onPress: () async {
                    final domain = domainCtrl.text.trim().toLowerCase();
                    if (domain.isNotEmpty) {
                      Navigator.pop(ctx);
                      await Get.find<DomainClassifier>().addSkipDomain(domain);
                      setState(() {});
                    }
                  },
                  child: Text('dialog_add'.tr),
                ),
              ),
            ],
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

    return Stack(
      children: [
        Column(
          children: [
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
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
        ),

        // ─── FAB ───
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton(
            heroTag: 'notif_fab',
            onPressed: () => _showComposeSheet(context, theme),
            backgroundColor: theme.colors.primary,
            child: const Icon(Icons.send_rounded, color: Colors.white),
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
                                            minWidth: double.infinity,
                                            maxWidth: double.infinity,
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
                                            minWidth: double.infinity,
                                            maxWidth: double.infinity,
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
                                            minWidth: double.infinity,
                                            maxWidth: double.infinity,
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
            constraints: BoxConstraints(
              minWidth: double.infinity,
              maxWidth: double.infinity,
            ),
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
