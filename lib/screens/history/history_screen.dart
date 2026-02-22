import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindsafe_flutter/app/controllers/vpn_controller.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';

enum ChartPeriod { daily, weekly, monthly }

/// Extract root domain from a full domain string.
/// e.g. g.whatsapp.net → whatsapp.net, graph.facebook.com → facebook.com
String _rootDomain(String domain) {
  final parts = domain.split('.');
  if (parts.length <= 2) return domain;
  return parts.sublist(parts.length - 2).join('.');
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;
  bool _todayExpanded = false;
  bool _weekExpanded = false;
  bool _monthExpanded = false;

  late final TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<String, bool> _calCategoryExpanded = {};
  final Map<String, bool> _calShowAll = {};
  final Map<String, bool> _tlShowAll = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
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
    final controller = Get.find<VpnController>();

    return FScaffold(
      header: FHeader(
        title: Text(
          'history_title'.tr,
          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      child: Column(
        children: [
          // ─── Tab Selector ───
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
                    const Icon(Icons.bar_chart_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('history_tab_overview'.tr),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('history_tab_calendar'.tr),
                  ],
                ),
              ),
            ],
          ),

          // ─── Tab Views ───
          Expanded(
            child: Obx(() {
              final userId = Get.find<AuthService>().currentUser?.uid ?? '';
              final allAccesses = db.userDomainAccess(userId)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              controller.todayDomainCount.value;

              if (allAccesses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'history_empty'.tr,
                        style: theme.typography.lg.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'history_empty_desc'.tr,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  // ═══ TAB 1: Overview (existing content) ═══
                  _buildOverviewTab(theme, allAccesses),
                  // ═══ TAB 2: Calendar ═══
                  _buildCalendarTab(theme, allAccesses),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: Overview ───
  Widget _buildOverviewTab(FThemeData theme, List<dynamic> allAccesses) {
    final chartData = _buildChartData(allAccesses, _selectedPeriod);
    final chartTitle = _getChartTitle(_selectedPeriod);
    final categoryData = _buildCategoryData(allAccesses);

    final grouped = <String, List<dynamic>>{};
    for (final access in allAccesses) {
      final dateKey = _formatDate(access.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(access);
    }

    // ─── Premium section builder (borderless) ───
    Widget sectionContainer({
      required Widget child,
      EdgeInsetsGeometry? padding,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.colors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
    }

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colors.foreground,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 10),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(chartTitle),
              Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  // Period selector
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: ChartPeriod.values.map((period) {
                        final isSelected = _selectedPeriod == period;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPeriod = period),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colors.foreground
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: theme.colors.foreground
                                              .withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                _getPeriodLabel(period),
                                textAlign: TextAlign.center,
                                style: theme.typography.sm.copyWith(
                                  color: isSelected
                                      ? theme.colors.background
                                      : theme.colors.mutedForeground,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Chart
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartData.isEmpty
                            ? 10
                            : chartData
                                      .map((e) => e.value)
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.3,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label = groupIndex < chartData.length
                                  ? chartData[groupIndex].tooltip
                                  : '';
                              return BarTooltipItem(
                                '$label\n${rod.toY.round()} ${'home_domains'.tr}',
                                TextStyle(
                                  color: theme.colors.foreground,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < chartData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      chartData[idx].label,
                                      style: theme.typography.xs.copyWith(
                                        color: theme.colors.mutedForeground,
                                        fontSize:
                                            _selectedPeriod ==
                                                ChartPeriod.monthly
                                            ? 9
                                            : 11,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getGridInterval(chartData),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.colors.border.withValues(alpha: 0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          chartData.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: chartData[i].value,
                                color: theme.colors.primary,
                                width: _getBarWidth(
                                  _selectedPeriod,
                                  chartData.length,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  _buildSummaryRow(chartData, theme),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Categories
        if (categoryData.isNotEmpty)
          sectionContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('history_categories'.tr),
                ...categoryData.entries.map((entry) {
                  final total = categoryData.values.fold<int>(
                    0,
                    (sum, v) => sum + v,
                  );
                  final pct = total > 0
                      ? (entry.value / total * 100).round()
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _categoryColor(
                              entry.key,
                              theme,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.value} ($pct%)',
                            style: theme.typography.xs.copyWith(
                              color: _categoryColor(entry.key, theme),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // Top Domains by Duration
        Builder(
          builder: (context) {
            // Aggregate per root-domain: total seconds + visit count
            final domainStats = <String, _DomainStat>{};
            for (final access in allAccesses) {
              final root = _rootDomain(access.domain);
              final stat = domainStats.putIfAbsent(root, () => _DomainStat());
              stat.totalSeconds += (access.durationSeconds as int);
              stat.visitCount += 1;
            }

            // Sort by duration descending, take top 10
            final sorted = domainStats.entries.toList()
              ..sort(
                (a, b) => b.value.totalSeconds.compareTo(a.value.totalSeconds),
              );
            final top = sorted.take(10).toList();
            final maxSeconds = top.isNotEmpty
                ? top.first.value.totalSeconds
                : 1;

            if (top.isEmpty) return const SizedBox();

            // Accent colors for top 3
            const topColors = [
              Color(0xFFF59E0B), // gold
              Color(0xFF94A3B8), // silver
              Color(0xFFCD7F32), // bronze
            ];

            return sectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('history_top_domains'.tr),
                  ...top.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final domain = entry.value.key;
                    final stat = entry.value.value;
                    final fraction = maxSeconds > 0
                        ? stat.totalSeconds / maxSeconds
                        : 0.0;
                    final isTop3 = idx < 3;
                    final badgeColor = isTop3
                        ? topColors[idx]
                        : theme.colors.mutedForeground;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: idx < top.length - 1 ? 10 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Rank badge
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(
                                alpha: isTop3 ? 0.12 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: theme.typography.xs.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Domain + progress bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        domain,
                                        style: theme.typography.sm.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: theme.colors.foreground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(stat.totalSeconds),
                                      style: theme.typography.xs.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isTop3
                                            ? badgeColor
                                            : theme.colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // Progress bar
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colors.muted.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: fraction.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isTop3
                                              ? [
                                                  badgeColor.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  badgeColor,
                                                ]
                                              : [
                                                  theme.colors.primary
                                                      .withValues(alpha: 0.6),
                                                  theme.colors.primary,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'history_visits'.trParams({
                                    'count': '${stat.visitCount}',
                                  }),
                                  style: theme.typography.xs.copyWith(
                                    fontSize: 10,
                                    color: theme.colors.mutedForeground
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Timeline Accordion ───
        Text(
          'history_timeline'.tr,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Builder(
          builder: (context) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final weekAgo = today.subtract(const Duration(days: 7));
            final monthAgo = today.subtract(const Duration(days: 30));

            // Aggregate by root domain per time period
            Map<String, int> aggregateDomains(List<dynamic> items) {
              final map = <String, int>{};
              for (final a in items) {
                final root = _rootDomain(a.domain);
                map.update(root, (v) => v + 1, ifAbsent: () => 1);
              }
              return map;
            }

            final todayRaw = allAccesses
                .where((a) => a.timestamp.isAfter(today))
                .toList();
            final weekRaw = allAccesses
                .where(
                  (a) =>
                      a.timestamp.isAfter(weekAgo) &&
                      a.timestamp.isBefore(today),
                )
                .toList();
            final monthRaw = allAccesses
                .where(
                  (a) =>
                      a.timestamp.isAfter(monthAgo) &&
                      a.timestamp.isBefore(weekAgo),
                )
                .toList();

            final todayDomains = aggregateDomains(todayRaw);
            final weekDomains = aggregateDomains(weekRaw);
            final monthDomains = aggregateDomains(monthRaw);

            Widget buildDomainRow(String domain, int visits) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: theme.colors.muted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        domain,
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'history_visits'.trParams({'count': '$visits'}),
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildAccordion({
              required String title,
              required int totalAccesses,
              required bool expanded,
              required ValueChanged<bool> onToggle,
              required Map<String, int> domainCounts,
              required String sectionKey,
            }) {
              final sorted = domainCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final showAll = _tlShowAll[sectionKey] ?? false;
              const previewLimit = 10;
              final displayList = showAll
                  ? sorted
                  : sorted.take(previewLimit).toList();
              final hasMore = sorted.length > previewLimit;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => onToggle(!expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: theme.colors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$title ($totalAccesses)',
                              style: theme.typography.sm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colors.foreground,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 22,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      children: [
                        ...displayList.map(
                          (e) => buildDomainRow(e.key, e.value),
                        ),
                        if (hasMore)
                          GestureDetector(
                            onTap: () => setState(() {
                              _tlShowAll[sectionKey] = !showAll;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    showAll
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: theme.colors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    showAll
                                        ? 'Show less'
                                        : 'Show all (${sorted.length})',
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              );
            }

            return Column(
              children: [
                if (todayDomains.isNotEmpty) ...[
                  buildAccordion(
                    title: 'history_today'.tr,
                    totalAccesses: todayRaw.length,
                    expanded: _todayExpanded,
                    onToggle: (v) => setState(() => _todayExpanded = v),
                    domainCounts: todayDomains,
                    sectionKey: 'today',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (weekDomains.isNotEmpty) ...[
                  buildAccordion(
                    title: 'history_this_week'.tr,
                    totalAccesses: weekRaw.length,
                    expanded: _weekExpanded,
                    onToggle: (v) => setState(() => _weekExpanded = v),
                    domainCounts: weekDomains,
                    sectionKey: 'week',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (monthDomains.isNotEmpty)
                  buildAccordion(
                    title: 'history_this_month'.tr,
                    totalAccesses: monthRaw.length,
                    expanded: _monthExpanded,
                    onToggle: (v) => setState(() => _monthExpanded = v),
                    domainCounts: monthDomains,
                    sectionKey: 'month',
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── Grid cell builder for calendar ───
  Widget _buildGridCell({
    required FThemeData theme,
    required DateTime day,
    required Color textColor,
    FontWeight fontWeight = FontWeight.w500,
    Color? bgColor,
    bool hasEvent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: theme.colors.border.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: theme.typography.sm.copyWith(
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
          if (hasEvent) ...[
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: bgColor != null
                    ? Colors.white.withValues(alpha: 0.8)
                    : theme.colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB 2: Calendar ───
  Widget _buildCalendarTab(FThemeData theme, List<dynamic> allAccesses) {
    // Build event map – key = date-only, value = list of accesses
    final eventMap = <DateTime, List<dynamic>>{};
    for (final a in allAccesses) {
      final d = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
      eventMap.putIfAbsent(d, () => []).add(a);
    }

    DateTime selectedNorm = DateTime(
      (_selectedDay ?? DateTime.now()).year,
      (_selectedDay ?? DateTime.now()).month,
      (_selectedDay ?? DateTime.now()).day,
    );

    final dayAccesses = eventMap[selectedNorm] ?? [];

    // Group by category, then aggregate by root domain
    final byCategory = <String, Map<String, int>>{};
    for (final a in dayAccesses) {
      final cat = a.category as String;
      final root = _rootDomain(a.domain);
      byCategory.putIfAbsent(cat, () => <String, int>{});
      byCategory[cat]!.update(root, (v) => v + 1, ifAbsent: () => 1);
    }
    // Sort categories alphabetically
    final sortedCategories = byCategory.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // ─── Calendar (Grid-style, edge-to-edge) ───
        TableCalendar(
          locale: Get.locale?.toString() ?? 'id_ID',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _calCategoryExpanded.clear();
              _calShowAll.clear();
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            final d = DateTime(day.year, day.month, day.day);
            return eventMap[d] ?? [];
          },
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          rowHeight: 52,
          daysOfWeekHeight: 32,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            headerPadding: const EdgeInsets.symmetric(vertical: 10),
            titleTextStyle: theme.typography.lg.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colors.foreground,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: theme.colors.foreground,
              size: 24,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: theme.colors.foreground,
              size: 24,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            weekendStyle: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
            outsideTextStyle: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground.withValues(alpha: 0.3),
            ),
            defaultTextStyle: theme.typography.sm.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
            weekendTextStyle: theme.typography.sm.copyWith(
              color: theme.colors.foreground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
            todayDecoration: const BoxDecoration(),
            todayTextStyle: theme.typography.sm.copyWith(
              color: theme.colors.primary,
              fontWeight: FontWeight.w800,
            ),
            selectedDecoration: const BoxDecoration(),
            selectedTextStyle: theme.typography.sm.copyWith(
              color: theme.colors.primary,
              fontWeight: FontWeight.w800,
            ),
            markerDecoration: BoxDecoration(
              color: theme.colors.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 0,
            markerMargin: const EdgeInsets.only(top: 2),
          ),
          calendarBuilders: CalendarBuilders(
            // Default day cell with border
            defaultBuilder: (context, day, focusedDay) {
              return _buildGridCell(
                theme: theme,
                day: day,
                textColor: theme.colors.foreground,
                hasEvent:
                    (eventMap[DateTime(day.year, day.month, day.day)] ?? [])
                        .isNotEmpty,
              );
            },
            // Today cell
            todayBuilder: (context, day, focusedDay) {
              return _buildGridCell(
                theme: theme,
                day: day,
                textColor: theme.colors.primary,
                fontWeight: FontWeight.w800,
                hasEvent:
                    (eventMap[DateTime(day.year, day.month, day.day)] ?? [])
                        .isNotEmpty,
              );
            },
            // Selected cell
            selectedBuilder: (context, day, focusedDay) {
              return _buildGridCell(
                theme: theme,
                day: day,
                textColor: Colors.white,
                fontWeight: FontWeight.w800,
                bgColor: theme.colors.primary,
                hasEvent: false, // no marker needed on selected
              );
            },
            // Outside (other month) cell
            outsideBuilder: (context, day, focusedDay) {
              return _buildGridCell(
                theme: theme,
                day: day,
                textColor: theme.colors.mutedForeground.withValues(alpha: 0.25),
                hasEvent: false,
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ─── Selected date header ───
        if (dayAccesses.isNotEmpty) ...[
          Text(
            'history_calendar_detail'.tr,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${dayAccesses.length} ${'history_calendar_accessed'.tr}',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Category Accordions (aggregated) ───
          ...sortedCategories.map((category) {
            final domainMap = byCategory[category]!;
            // Sort by visit count descending
            final sortedDomains = domainMap.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final totalInCat = sortedDomains.fold<int>(
              0,
              (sum, e) => sum + e.value,
            );
            final isExpanded = _calCategoryExpanded[category] ?? false;
            final showAll = _calShowAll[category] ?? false;
            final catColor = _categoryColor(category, theme);

            const previewLimit = 10;
            final displayList = showAll
                ? sortedDomains
                : sortedDomains.take(previewLimit).toList();
            final hasMore = sortedDomains.length > previewLimit;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category header ──
                  GestureDetector(
                    onTap: () => setState(() {
                      _calCategoryExpanded[category] = !isExpanded;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$category ($totalInCat)',
                              style: theme.typography.sm.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colors.foreground,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 22,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Expanded aggregated domain list ──
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      children: [
                        ...displayList.map((entry) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colors.muted.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colors.border.withValues(
                                  alpha: 0.3,
                                ),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: theme.typography.sm.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colors.foreground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'history_visits'.trParams({
                                    'count': '${entry.value}',
                                  }),
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Show more / less toggle
                        if (hasMore)
                          GestureDetector(
                            onTap: () => setState(() {
                              _calShowAll[category] = !showAll;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    showAll
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: theme.colors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    showAll
                                        ? 'Show less'
                                        : 'Show all (${sortedDomains.length})',
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 48,
                  color: theme.colors.mutedForeground.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'history_calendar_empty'.tr,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Period helpers ───

  String _getPeriodLabel(ChartPeriod period) {
    switch (period) {
      case ChartPeriod.daily:
        return 'history_daily'.tr;
      case ChartPeriod.weekly:
        return 'history_weekly'.tr;
      case ChartPeriod.monthly:
        return 'history_monthly'.tr;
    }
  }

  String _getChartTitle(ChartPeriod period) {
    switch (period) {
      case ChartPeriod.daily:
        return 'history_daily_title'.tr;
      case ChartPeriod.weekly:
        return 'history_weekly_title'.tr;
      case ChartPeriod.monthly:
        return 'history_monthly_title'.tr;
    }
  }

  double _getBarWidth(ChartPeriod period, int count) {
    switch (period) {
      case ChartPeriod.daily:
        return 16;
      case ChartPeriod.weekly:
        return 24;
      case ChartPeriod.monthly:
        return 6;
    }
  }

  double _getGridInterval(List<_ChartPoint> data) {
    if (data.isEmpty) return 5;
    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 10) return 2;
    if (maxVal <= 50) return 10;
    return 20;
  }

  // ─── Chart data builders ───

  List<_ChartPoint> _buildChartData(
    List<dynamic> accesses,
    ChartPeriod period,
  ) {
    switch (period) {
      case ChartPeriod.daily:
        return _buildDailyData(accesses);
      case ChartPeriod.weekly:
        return _buildWeeklyData(accesses);
      case ChartPeriod.monthly:
        return _buildMonthlyData(accesses);
    }
  }

  List<_ChartPoint> _buildDailyData(List<dynamic> accesses) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final result = <_ChartPoint>[];

    for (int h = 0; h < 24; h++) {
      final hourStart = todayStart.add(Duration(hours: h));
      final hourEnd = hourStart.add(const Duration(hours: 1));

      final count = accesses
          .where(
            (a) =>
                a.timestamp.isAfter(hourStart) && a.timestamp.isBefore(hourEnd),
          )
          .map((a) => a.domain)
          .toSet()
          .length;

      final label = h % 3 == 0 ? h.toString().padLeft(2, '0') : '';
      final tooltip =
          '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00';

      result.add(
        _ChartPoint(label: label, value: count.toDouble(), tooltip: tooltip),
      );
    }
    return result;
  }

  List<_ChartPoint> _buildWeeklyData(List<dynamic> accesses) {
    final days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final result = <_ChartPoint>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = accesses
          .where(
            (a) =>
                a.timestamp.isAfter(dayStart) && a.timestamp.isBefore(dayEnd),
          )
          .map((a) => a.domain)
          .toSet()
          .length;

      final dayLabel = days[date.weekday - 1];
      final tooltip = '${date.day}/${date.month} ($dayLabel)';
      result.add(
        _ChartPoint(label: dayLabel, value: count.toDouble(), tooltip: tooltip),
      );
    }
    return result;
  }

  List<_ChartPoint> _buildMonthlyData(List<dynamic> accesses) {
    final now = DateTime.now();
    final result = <_ChartPoint>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = accesses
          .where(
            (a) =>
                a.timestamp.isAfter(dayStart) && a.timestamp.isBefore(dayEnd),
          )
          .map((a) => a.domain)
          .toSet()
          .length;

      final label = i % 5 == 0 ? '${date.day}/${date.month}' : '';
      final tooltip = '${date.day}/${date.month}/${date.year}';
      result.add(
        _ChartPoint(label: label, value: count.toDouble(), tooltip: tooltip),
      );
    }
    return result;
  }

  // ─── Summary row ───

  Widget _buildSummaryRow(List<_ChartPoint> data, FThemeData theme) {
    final total = data.fold<double>(0, (sum, p) => sum + p.value);
    final avg = data.isNotEmpty ? (total / data.length) : 0.0;
    final max = data.isNotEmpty
        ? data.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SummaryItem(
          label: 'history_total'.tr,
          value: total.round().toString(),
          theme: theme,
        ),
        _SummaryItem(
          label: 'history_average'.tr,
          value: avg.toStringAsFixed(1),
          theme: theme,
        ),
        _SummaryItem(
          label: 'history_highest'.tr,
          value: max.round().toString(),
          theme: theme,
        ),
      ],
    );
  }

  // ─── Shared helpers ───

  Map<String, int> _buildCategoryData(List<dynamic> accesses) {
    final cats = <String, int>{};
    for (final access in accesses) {
      cats[access.category] = (cats[access.category] ?? 0) + 1;
    }
    return cats;
  }

  Color _categoryColor(String category, FThemeData theme) {
    switch (category) {
      case 'adult':
        return theme.colors.error;
      case 'safe':
        return Colors.green;
      default:
        return theme.colors.mutedForeground;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'history_today'.tr;
    if (date == today.subtract(const Duration(days: 1))) {
      return 'history_yesterday'.tr;
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return 'history_seconds'.trParams({'count': '$totalSeconds'});
    }
    final hrs = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hrs > 0) {
      return 'history_hours_min'.trParams({'hrs': '$hrs', 'min': '$mins'});
    }
    return 'history_min_sec'.trParams({'min': '$mins', 'sec': '$secs'});
  }
}

class _ChartPoint {
  final String label;
  final double value;
  final String tooltip;
  const _ChartPoint({
    required this.label,
    required this.value,
    this.tooltip = '',
  });
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final FThemeData theme;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _DomainStat {
  int totalSeconds = 0;
  int visitCount = 0;
}
