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

  late final TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<String, bool> _calCategoryExpanded = {};
  final Map<String, bool> _calShowAll = {};

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

              controller
                  .accessCount
                  .value; // rebuilds on every new access record

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
    final categoryChartData = _buildChartDataByCategory(
      allAccesses,
      _selectedPeriod,
    );
    const accent = Color(0xFF6C63FF);

    // x-axis labels: always use full slot list (not from first category)
    // so all categories have aligned points regardless of when they appeared
    final xLabels = switch (_selectedPeriod) {
      ChartPeriod.daily => _buildDailyData([]),
      ChartPeriod.weekly => _buildWeeklyData([]),
      ChartPeriod.monthly => _buildMonthlyData([]),
    };

    final hasData = categoryChartData.values.any(
      (pts) => pts.any((p) => p.value > 0),
    );

    // ── Stat chips: Total Durasi, % Berbahaya, Jam Tersibuk ──
    // Total duration across all accesses (all-time for overview)
    final int totalSeconds = allAccesses.fold<int>(
      0,
      (s, a) => s + (a.durationSeconds as int? ?? 0),
    );

    // % unsafe content (adult + gambling)
    final int totalRecs = allAccesses.length;
    final int unsafeRecs = allAccesses
        .where((a) => a.category == 'adult' || a.category == 'gambling')
        .length;
    final int unsafePct = totalRecs > 0
        ? ((unsafeRecs / totalRecs) * 100).round()
        : 0;

    // Peak hour (today only)
    final now2 = DateTime.now();
    final todayStartStat = DateTime(now2.year, now2.month, now2.day);
    final hourCounts = List.filled(24, 0);
    for (final a in allAccesses) {
      if (!a.timestamp.isAfter(todayStartStat)) continue;
      final h = (a.timestamp as DateTime).hour;
      hourCounts[h] += 1;
    }
    final peakHour = hourCounts.indexOf(
      hourCounts.reduce((a, b) => a > b ? a : b),
    );
    final peakHourLabel = hourCounts.reduce((a, b) => a > b ? a : b) == 0
        ? '--'
        : '${peakHour.toString().padLeft(2, '0')}:00';

    Widget card({
      required Widget child,
      bool noPad = false,
      bool bordered = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          border: bordered
              ? Border.all(
                  color: theme.colors.border.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
          borderRadius: bordered ? BorderRadius.circular(12) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: bordered
            ? const EdgeInsets.symmetric(horizontal: 6)
            : EdgeInsets.zero,
        padding: noPad
            ? null
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      );
    }

    Widget sectionLabel(String text) => Text(
      text,
      style: theme.typography.sm.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colors.foreground,
        letterSpacing: 0.3,
      ),
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        card(
          noPad: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    Expanded(child: sectionLabel('history_chart_activity'.tr)),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colors.muted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ChartPeriod.values.map((p) {
                          final sel = _selectedPeriod == p;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPeriod = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                _getPeriodLabel(p),
                                style: theme.typography.xs.copyWith(
                                  color: sel
                                      ? Colors.white
                                      : theme.colors.mutedForeground,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: !hasData
                    ? Center(
                        child: Text(
                          'history_no_data'.tr,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: _getGridInterval(xLabels),
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: theme.colors.border.withValues(
                                  alpha: 0.18,
                                ),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
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
                                  reservedSize: 28,
                                  getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  interval: 1,
                                  getTitlesWidget: (v, meta) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= xLabels.length) {
                                      return const SizedBox();
                                    }
                                    final lbl = xLabels[idx].label;
                                    if (lbl.isEmpty) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        lbl,
                                        style: theme.typography.xs.copyWith(
                                          color: theme.colors.mutedForeground,
                                          fontSize:
                                              _selectedPeriod ==
                                                  ChartPeriod.monthly
                                              ? 8
                                              : 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => theme.colors.background,
                                tooltipRoundedRadius: 10,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItems: (spots) {
                                  final cats = categoryChartData.keys.toList();
                                  return spots.asMap().entries.map((e) {
                                    final spot = e.value;
                                    final idx = spot.x.toInt();
                                    final catIdx = e.key;
                                    final cat = catIdx < cats.length
                                        ? cats[catIdx]
                                        : '';
                                    final timeLabel = idx < xLabels.length
                                        ? xLabels[idx].tooltip
                                        : '';
                                    final catColor = _categoryColor2(cat);
                                    return LineTooltipItem(
                                      catIdx == 0 ? '$timeLabel\n' : '',
                                      theme.typography.xs.copyWith(
                                        color: theme.colors.mutedForeground,
                                        fontSize: 10,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$cat: ${spot.y.round()}',
                                          style: TextStyle(
                                            color: catColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                              handleBuiltInTouches: true,
                            ),
                            minY: 0,
                            lineBarsData: categoryChartData.entries.map((
                              entry,
                            ) {
                              final cat = entry.key;
                              final pts = entry.value;
                              final color = _categoryColor2(cat);
                              return LineChartBarData(
                                spots: List.generate(
                                  pts.length,
                                  (i) => FlSpot(i.toDouble(), pts[i].value),
                                ),
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: color,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: pts.length <= 7,
                                  getDotPainter: (_, __, ___, ____) =>
                                      FlDotCirclePainter(
                                        radius: 3.5,
                                        color: color,
                                        strokeWidth: 1.5,
                                        strokeColor: theme.colors.background,
                                      ),
                                ),
                                belowBarData: BarAreaData(
                                  show: categoryChartData.length == 1,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color.withValues(alpha: 0.2),
                                      color.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                      ),
              ),
              // ── Legend ──
              if (categoryChartData.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: categoryChartData.keys.map((cat) {
                      final color = _categoryColor2(cat);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 3,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat,
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              // ─── Unified Stat Card (Home-style: border, icon, value) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colors.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.timer_outlined,
                          label: 'history_stat_duration'.tr,
                          value: () {
                            if (totalSeconds <= 0) return '0 dtk';
                            final h = totalSeconds ~/ 3600;
                            final m = (totalSeconds % 3600) ~/ 60;
                            final s = totalSeconds % 60;
                            if (h > 0) return '$h j';
                            if (m > 0) return '$m mnt';
                            return '$s dtk';
                          }(),
                          accent: accent,
                          theme: theme,
                        ),
                        VerticalDivider(
                          color: theme.colors.border.withValues(alpha: 0.4),
                          thickness: 1,
                          indent: 4,
                          endIndent: 4,
                        ),
                        _StatChip(
                          icon: Icons.warning_amber_rounded,
                          label: 'history_stat_dangerous'.tr,
                          value: '$unsafePct%',
                          accent: theme.colors.error,
                          theme: theme,
                        ),
                        VerticalDivider(
                          color: theme.colors.border.withValues(alpha: 0.4),
                          thickness: 1,
                          indent: 4,
                          endIndent: 4,
                        ),
                        _StatChip(
                          icon: Icons.access_time_rounded,
                          label: 'history_stat_peak_hour'.tr,
                          value: peakHourLabel,
                          accent: const Color(0xFFF59E0B),
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Builder(
          builder: (context) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);

            final domainStats = <String, _DomainStat>{};
            for (final access in allAccesses) {
              // Only count records from today to match Home Screen
              if (!access.timestamp.isAfter(todayStart)) continue;
              final root = _rootDomain(access.domain);
              if (root.isEmpty) continue;
              final stat = domainStats.putIfAbsent(root, () => _DomainStat());
              stat.totalSeconds += (access.durationSeconds as int);
              stat.visitCount += 1;
            }

            // Inject real-time duration for the currently active session
            // (not yet committed to DB) so the display is always up-to-date.
            try {
              final vpn = Get.find<VpnController>();
              final activeDomain = vpn.activeSessionDomain;
              final activeSec = vpn.activeSessionSeconds;
              if (activeDomain != null && activeSec > 0) {
                final root = _rootDomain(activeDomain);
                if (root.isNotEmpty) {
                  final stat = domainStats[root];
                  if (stat != null) {
                    stat.totalSeconds += activeSec;
                    // Count the still-open session as 1 visit
                    stat.visitCount += 1;
                  }
                }
              }
            } catch (_) {
              // VpnController not available — skip live injection
            }

            final sorted = domainStats.entries.toList()
              ..sort(
                (a, b) => b.value.visitCount.compareTo(a.value.visitCount),
              );
            final top = sorted.take(10).toList();
            final domainCategory = <String, String>{};
            for (final access in allAccesses) {
              if (!access.timestamp.isAfter(todayStart)) continue;
              final root = _rootDomain(access.domain);
              if (root.isNotEmpty) {
                domainCategory[root] = access.category ?? 'safe';
              }
            }

            const podiumColors = [
              Color(0xFFF59E0B),
              Color(0xFF94A3B8),
              Color(0xFFCD7F32),
            ];

            if (top.isEmpty) return const SizedBox();

            return card(
              noPad: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Row(
                      children: [
                        Expanded(child: sectionLabel('history_top_domains'.tr)),
                        Text(
                          'history_today'.tr,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...top.asMap().entries.map((e) {
                    final idx = e.key;
                    final domain = e.value.key;
                    final stat = e.value.value;
                    final maxVisit = top.first.value.visitCount;
                    final fraction = maxVisit > 0
                        ? stat.visitCount / maxVisit
                        : 0.0;
                    final isTop = idx < 3;
                    final badgeColor = isTop
                        ? podiumColors[idx]
                        : theme.colors.mutedForeground;
                    final cat = domainCategory[domain] ?? 'safe';
                    final catColor = _categoryColor(cat, theme);

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        0,
                        14,
                        idx < top.length - 1 ? 10 : 14,
                      ),
                      child: Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTop
                                  ? badgeColor.withValues(alpha: 0.15)
                                  : theme.colors.muted.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: theme.typography.xs.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Category dot
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 5),
                                      decoration: BoxDecoration(
                                        color: catColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        domain,
                                        style: theme.typography.sm.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colors.foreground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${stat.visitCount}x',
                                      style: theme.typography.xs.copyWith(
                                        color: isTop
                                            ? badgeColor
                                            : theme.colors.mutedForeground,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (stat.totalSeconds > 0) ...[
                                      Text(
                                        ' · ${_formatDuration(stat.totalSeconds)}',
                                        style: theme.typography.xs.copyWith(
                                          color: theme.colors.mutedForeground,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: fraction.clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: theme.colors.muted
                                        .withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      isTop
                                          ? badgeColor.withValues(alpha: 0.7)
                                          : catColor.withValues(alpha: 0.5),
                                    ),
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

    // Group by category, then aggregate by root domain (visit count + duration)
    final byCategory = <String, Map<String, _DomainStat>>{};
    for (final a in dayAccesses) {
      final cat = a.category as String;
      final root = _rootDomain(a.domain);
      if (root.isEmpty) continue;
      byCategory.putIfAbsent(cat, () => <String, _DomainStat>{});
      final stat = byCategory[cat]!.putIfAbsent(root, () => _DomainStat());
      stat.visitCount += 1;
      stat.totalSeconds += (a.durationSeconds as int? ?? 0);
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
              ..sort(
                (a, b) => b.value.visitCount.compareTo(a.value.visitCount),
              );
            final totalInCat = sortedDomains.fold<int>(
              0,
              (sum, e) => sum + e.value.visitCount,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                        'count': '${entry.value.visitCount}',
                                      }),
                                      style: theme.typography.xs.copyWith(
                                        color: theme.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                if (entry.value.totalSeconds > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDuration(entry.value.totalSeconds),
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.mutedForeground
                                          .withValues(alpha: 0.6),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
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

  double _getGridInterval(List<_ChartPoint> data) {
    if (data.isEmpty) return 5;
    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 10) return 2;
    if (maxVal <= 50) return 10;
    return 20;
  }

  /// Build chart data split by category.
  Map<String, List<_ChartPoint>> _buildChartDataByCategory(
    List<dynamic> accesses,
    ChartPeriod period,
  ) {
    final categories =
        accesses.map((a) => (a.category as String? ?? 'safe')).toSet().toList()
          ..sort();

    if (categories.isEmpty) return {};

    final result = <String, List<_ChartPoint>>{};
    for (final cat in categories) {
      final filtered = accesses
          .where((a) => (a.category as String? ?? 'safe') == cat)
          .toList();
      switch (period) {
        case ChartPeriod.daily:
          result[cat] = _buildDailyData(filtered);
        case ChartPeriod.weekly:
          result[cat] = _buildWeeklyData(filtered);
        case ChartPeriod.monthly:
          result[cat] = _buildMonthlyData(filtered);
      }
    }
    return result;
  }

  Color _categoryColor2(String category) {
    switch (category.toLowerCase()) {
      case 'safe':
        return const Color(0xFF10B981);
      case 'adult':
        return const Color(0xFFEC4899);
      case 'gambling':
        return const Color(0xFFF59E0B);
      case 'phishing':
        return const Color(0xFFEF4444);
      case 'malware':
        return const Color(0xFF8B5CF6);
      case 'mixed':
        return const Color(0xFF06B6D4);
      case 'cryptojacking':
        return const Color(0xFFF97316);
      case 'drugs':
        return const Color(0xFF84CC16);
      case 'hacking':
        return const Color(0xFF6366F1);
      case 'dangerous':
        return const Color(0xFFDC2626);
      case 'dating':
        return const Color(0xFFDB2777);
      case 'ddos':
        return const Color(0xFF7C3AED);
      case 'warez':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  List<_ChartPoint> _buildDailyData(List<dynamic> accesses) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final result = <_ChartPoint>[];

    for (int h = 0; h < 24; h++) {
      final hourStart = todayStart.add(Duration(hours: h));
      final hourEnd = hourStart.add(const Duration(hours: 1));

      // Count total visit records in this hour (not unique domains)
      final count = accesses
          .where(
            (a) =>
                a.timestamp.isAfter(hourStart) && a.timestamp.isBefore(hourEnd),
          )
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

      // Count total visit records per day (not unique domains)
      final count = accesses
          .where(
            (a) =>
                a.timestamp.isAfter(dayStart) && a.timestamp.isBefore(dayEnd),
          )
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

      // Count total visit records per day (not unique domains)
      final count = accesses
          .where(
            (a) =>
                a.timestamp.isAfter(dayStart) && a.timestamp.isBefore(dayEnd),
          )
          .length;

      final label = i % 5 == 0 ? '${date.day}/${date.month}' : '';
      final tooltip = '${date.day}/${date.month}/${date.year}';
      result.add(
        _ChartPoint(label: label, value: count.toDouble(), tooltip: tooltip),
      );
    }
    return result;
  }

  // ─── Shared helpers ───

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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final FThemeData theme;
  final IconData? icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.accent,
    required this.theme,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: theme.colors.mutedForeground.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DomainStat {
  int totalSeconds = 0;
  int visitCount = 0;
}
