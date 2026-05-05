import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sale_record.dart';
import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import '../services/analytics_service.dart';
import '../utils/currency_format.dart';
import '../widgets/charts/sales_line_chart.dart';
import '../widgets/section_header.dart';

enum _TrendRange {
  sevenDays,
  oneMonth,
  oneYear;

  int get dayCount => switch (this) {
        sevenDays => 7,
        oneMonth => 30,
        oneYear => 365,
      };

  String get label => switch (this) {
        sevenDays => '7 days',
        oneMonth => '1 month',
        oneYear => '1 year',
      };
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _TrendRange _trendRange = _TrendRange.sevenDays;

  ({List<FlSpot> spots, List<String> labels}) _trendSeries(
    List<SaleRecord> sales,
    int days,
  ) {
    final daily = AnalyticsService.dailyRevenueSeries(sales, days);
    final sortedDays = daily.keys.toList()..sort();
    final spots = <FlSpot>[
      for (var i = 0; i < sortedDays.length; i++)
        FlSpot(i.toDouble(), daily[sortedDays[i]] ?? 0),
    ];
    final labels = <String>[];
    final dfShort = DateFormat.E();
    final dfDm = DateFormat('d/M');
    final dfMonth = DateFormat('MMM');
    for (var i = 0; i < sortedDays.length; i++) {
      final d = sortedDays[i];
      if (days <= 14) {
        labels.add(dfShort.format(d));
      } else if (days <= 31) {
        labels.add(i % 5 == 0 ? dfDm.format(d) : '');
      } else {
        final prev = i > 0 ? sortedDays[i - 1] : null;
        final show = i == 0 ||
            prev == null ||
            d.month != prev.month ||
            d.year != prev.year ||
            i % 45 == 0;
        labels.add(show ? dfMonth.format(d) : '');
      }
    }
    return (spots: spots, labels: labels);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryNotifier>();
    final cc = context.watch<SettingsNotifier>().currencyCode;

    if (!inv.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final days = _trendRange.dayCount;
    final trendData = _trendSeries(inv.sales, days);

    final week = AnalyticsService.totalsForWeek(inv.sales, now);
    final month = AnalyticsService.totalsForMonth(inv.sales, now);
    final year = AnalyticsService.totalsForYear(inv.sales, now);

    final monthlyMap = AnalyticsService.monthlyRevenueYear(inv.sales, now.year);
    final monthLabels = List.generate(12, (i) => DateFormat.MMM().format(DateTime(now.year, i + 1)));
    final monthValues = List.generate(12, (i) => monthlyMap[i + 1] ?? 0);

    final perf = AnalyticsService.productPerformance(inv.sales);
    final best = perf.take(8).toList();
    final low = AnalyticsService.lowPerformingProducts(inv.products, inv.sales);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionHeader(title: 'Sales trend (${_trendRange.label})'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_TrendRange>(
                  segments: const [
                    ButtonSegment<_TrendRange>(
                      value: _TrendRange.sevenDays,
                      label: Text('7 days'),
                      icon: Icon(Icons.view_week_outlined, size: 18),
                    ),
                    ButtonSegment<_TrendRange>(
                      value: _TrendRange.oneMonth,
                      label: Text('1 month'),
                      icon: Icon(Icons.calendar_month_outlined, size: 18),
                    ),
                    ButtonSegment<_TrendRange>(
                      value: _TrendRange.oneYear,
                      label: Text('1 year'),
                      icon: Icon(Icons.timeline_outlined, size: 18),
                    ),
                  ],
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  selected: {_trendRange},
                  onSelectionChanged: (selection) {
                    setState(() => _trendRange = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                SalesLineChart(
                  spots: trendData.spots,
                  currencyCode: cc,
                  title: '',
                  xAxisLabels: trendData.labels,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Performance windows'),
        _metricRow(context, cc, 'This week', week.revenue, week.unitsSold),
        const SizedBox(height: 8),
        _metricRow(context, cc, 'This month', month.revenue, month.unitsSold),
        const SizedBox(height: 8),
        _metricRow(context, cc, 'This year', year.revenue, year.unitsSold),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Yearly revenue by month'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: monthValues.fold<double>(0, (a, b) => a > b ? a : b) * 1.15 + 1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= 12) return const SizedBox.shrink();
                          return Text(
                            monthLabels[i],
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value > meta.max || value < meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value >= 1000
                                ? '${(value / 1000).toStringAsFixed(1)}k'
                                : value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < 12; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: monthValues[i],
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Best selling products'),
        if (best.isEmpty)
          _emptyHint(context, 'Sell items to populate rankings.')
        else
          ...best.map(
            (e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(e.name),
                subtitle: Text('${e.quantitySold} units sold'),
                trailing: Text(
                  formatMoney(e.revenue, cc),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Low performing products'),
        if (low.isEmpty)
          _emptyHint(context, 'No catalog items.')
        else
          ...low.map(
            (p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(p.name),
                subtitle: Text('Stock ${p.stock} · Lifetime sold ${p.sold}'),
                trailing: Icon(
                  Icons.trending_down,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _metricRow(
    BuildContext context,
    String cc,
    String label,
    double rev,
    int units,
  ) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text('$units units moved'),
        trailing: Text(
          formatMoney(rev, cc),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
        ),
      ),
    );
  }
}
