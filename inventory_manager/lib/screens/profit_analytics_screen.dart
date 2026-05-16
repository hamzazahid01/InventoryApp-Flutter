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
import '../widgets/metric_card.dart';
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

/// Revenue & profit analytics — two dedicated sections on one screen.
class RevenueProfitAnalyticsScreen extends StatefulWidget {
  const RevenueProfitAnalyticsScreen({super.key});

  @override
  State<RevenueProfitAnalyticsScreen> createState() =>
      _RevenueProfitAnalyticsScreenState();
}

/// @deprecated Use [RevenueProfitAnalyticsScreen].
typedef ProfitAnalyticsScreen = RevenueProfitAnalyticsScreen;

class _RevenueProfitAnalyticsScreenState
    extends State<RevenueProfitAnalyticsScreen> {
  _TrendRange _trendRange = _TrendRange.sevenDays;

  ({List<FlSpot> spots, List<String> labels}) _dailyTrend(
    List<SaleRecord> sales,
    int days, {
    required bool profit,
  }) {
    final daily = profit
        ? AnalyticsService.dailyProfitSeries(sales, days)
        : AnalyticsService.dailyRevenueSeries(sales, days);
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
    final revenueTrend = _dailyTrend(inv.sales, days, profit: false);
    final profitTrend = _dailyTrend(inv.sales, days, profit: true);

    final today = inv.salesToday();
    final week = inv.salesThisWeek();
    final month = inv.salesThisMonth();
    final year = inv.salesThisYear();

    final monthlyRevenue =
        AnalyticsService.monthlyRevenueYear(inv.sales, now.year);
    final monthlyProfit =
        AnalyticsService.monthlyProfitYear(inv.sales, now.year);
    final monthLabels = List.generate(
      12,
      (i) => DateFormat.MMM().format(DateTime(now.year, i + 1)),
    );
    final revenueMonthValues =
        List.generate(12, (i) => monthlyRevenue[i + 1] ?? 0);
    final profitMonthValues =
        List.generate(12, (i) => monthlyProfit[i + 1] ?? 0);

    final topRevenue = AnalyticsService.topRevenueProducts(inv.sales);
    final recentRevenue = AnalyticsService.recentSales(inv.sales);
    final topProfit = AnalyticsService.topProfitProducts(inv.sales);
    final recentProfit = AnalyticsService.recentProfitableSales(inv.sales);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: 0.35,
              ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Revenue & profit analytics',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _AnalyticsSectionHeader(
          title: 'Revenue',
          subtitle: 'Total sales income from recorded transactions',
          icon: Icons.payments_outlined,
          accent: Colors.blue.shade700,
        ),
        const SizedBox(height: 12),
        _PeriodMetricGrid(
          currencyCode: cc,
          totalTitle: 'Total revenue',
          totalValue: formatMoney(inv.totalRevenue, cc),
          totalIcon: Icons.account_balance_wallet_outlined,
          totalAccent: Colors.blue.shade700,
          today: today,
          week: week,
          month: month,
          year: year,
          valueOf: (t) => t.revenue,
        ),
        const SizedBox(height: 16),
        _TrendChartCard(
          title: 'Revenue trend (${_trendRange.label})',
          trendRange: _trendRange,
          onRangeChanged: (r) => setState(() => _trendRange = r),
          spots: revenueTrend.spots,
          labels: revenueTrend.labels,
          currencyCode: cc,
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Yearly revenue by month'),
        _MonthlyBarChart(
          monthLabels: monthLabels,
          monthValues: revenueMonthValues,
          barColor: Colors.blue.shade600,
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Top revenue products'),
        if (topRevenue.isEmpty)
          _emptyHint(context, 'Record sales to see revenue rankings.')
        else
          ...topRevenue.map(
            (e) => _ProductRankTile(
              name: e.name,
              subtitle:
                  '${e.quantitySold} units · Profit ${formatMoney(e.profit, cc)}',
              trailing: formatMoney(e.revenue, cc),
              trailingColor: Colors.blue.shade700,
              icon: Icons.leaderboard_outlined,
              iconColor: Colors.blue.shade700,
            ),
          ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Recent sales (revenue)'),
        if (recentRevenue.isEmpty)
          _emptyHint(context, 'No sales recorded yet.')
        else
          ...recentRevenue.map(
            (s) => _RecentSaleTile(
              sale: s,
              currencyCode: cc,
              trailing: formatMoney(s.totalSaleAmount, cc),
              trailingColor: Colors.blue.shade700,
            ),
          ),
        const SizedBox(height: 28),
        const Divider(height: 32),
        _AnalyticsSectionHeader(
          title: 'Profit',
          subtitle: 'Margin after cost — selling price minus cost price',
          icon: Icons.trending_up,
          accent: Colors.green.shade700,
        ),
        const SizedBox(height: 12),
        _PeriodMetricGrid(
          currencyCode: cc,
          totalTitle: 'Total profit',
          totalValue: formatMoney(inv.totalProfit, cc),
          totalIcon: Icons.trending_up,
          totalAccent: Colors.green.shade700,
          today: today,
          week: week,
          month: month,
          year: year,
          valueOf: (t) => t.profit,
        ),
        const SizedBox(height: 16),
        _TrendChartCard(
          title: 'Profit trend (${_trendRange.label})',
          trendRange: _trendRange,
          onRangeChanged: (r) => setState(() => _trendRange = r),
          spots: profitTrend.spots,
          labels: profitTrend.labels,
          currencyCode: cc,
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Yearly profit by month'),
        _MonthlyBarChart(
          monthLabels: monthLabels,
          monthValues: profitMonthValues,
          barColor: Colors.green.shade600,
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Best profit products'),
        if (topProfit.isEmpty)
          _emptyHint(context, 'Record sales with margin to see rankings.')
        else
          ...topProfit.map(
            (e) => _ProductRankTile(
              name: e.name,
              subtitle:
                  '${e.quantitySold} units · Revenue ${formatMoney(e.revenue, cc)}',
              trailing: formatMoney(e.profit, cc),
              trailingColor: Colors.green.shade700,
              icon: Icons.star,
              iconColor: Colors.green.shade700,
            ),
          ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Recent profitable sales'),
        if (recentProfit.isEmpty)
          _emptyHint(context, 'No profitable sales yet.')
        else
          ...recentProfit.map(
            (s) => _RecentSaleTile(
              sale: s,
              currencyCode: cc,
              trailing: '+${formatMoney(s.profit, cc)}',
              trailingColor: Colors.green.shade700,
            ),
          ),
      ],
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ),
    );
  }
}

class _AnalyticsSectionHeader extends StatelessWidget {
  const _AnalyticsSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodMetricGrid extends StatelessWidget {
  const _PeriodMetricGrid({
    required this.currencyCode,
    required this.totalTitle,
    required this.totalValue,
    required this.totalIcon,
    required this.totalAccent,
    required this.today,
    required this.week,
    required this.month,
    required this.year,
    required this.valueOf,
  });

  final String currencyCode;
  final String totalTitle;
  final String totalValue;
  final IconData totalIcon;
  final Color totalAccent;
  final PeriodTotals today;
  final PeriodTotals week;
  final PeriodTotals month;
  final PeriodTotals year;
  final double Function(PeriodTotals) valueOf;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final cards = [
          MetricCard(
            title: totalTitle,
            value: totalValue,
            subtitle: 'all recorded sales',
            icon: totalIcon,
            accentColor: totalAccent,
          ),
          MetricCard(
            title: 'Today',
            value: formatMoney(valueOf(today), currencyCode),
            subtitle: '${today.unitsSold} units',
            icon: Icons.today_outlined,
          ),
          MetricCard(
            title: 'This week',
            value: formatMoney(valueOf(week), currencyCode),
            subtitle: '${week.unitsSold} units',
            icon: Icons.date_range_outlined,
            accentColor: Colors.teal,
          ),
          MetricCard(
            title: 'This month',
            value: formatMoney(valueOf(month), currencyCode),
            subtitle: '${month.unitsSold} units',
            icon: Icons.calendar_month_outlined,
            accentColor: Colors.deepPurple,
          ),
          MetricCard(
            title: 'This year',
            value: formatMoney(valueOf(year), currencyCode),
            subtitle: '${year.unitsSold} units',
            icon: Icons.timeline_outlined,
            accentColor: Colors.orange.shade800,
          ),
        ];
        if (wide) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in cards)
                SizedBox(
                  width: (constraints.maxWidth - 24) / 3,
                  child: c,
                ),
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard({
    required this.title,
    required this.trendRange,
    required this.onRangeChanged,
    required this.spots,
    required this.labels,
    required this.currencyCode,
  });

  final String title;
  final _TrendRange trendRange;
  final ValueChanged<_TrendRange> onRangeChanged;
  final List<FlSpot> spots;
  final List<String> labels;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: title),
            SegmentedButton<_TrendRange>(
              segments: const [
                ButtonSegment(
                  value: _TrendRange.sevenDays,
                  label: Text('7 days'),
                ),
                ButtonSegment(
                  value: _TrendRange.oneMonth,
                  label: Text('1 month'),
                ),
                ButtonSegment(
                  value: _TrendRange.oneYear,
                  label: Text('1 year'),
                ),
              ],
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              selected: {trendRange},
              onSelectionChanged: (s) => onRangeChanged(s.first),
            ),
            const SizedBox(height: 12),
            SalesLineChart(
              spots: spots,
              currencyCode: currencyCode,
              title: '',
              xAxisLabels: labels,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({
    required this.monthLabels,
    required this.monthValues,
    required this.barColor,
  });

  final List<String> monthLabels;
  final List<double> monthValues;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final maxY =
        monthValues.fold<double>(0, (a, b) => a > b ? a : b) * 1.15 + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.12),
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
                      if (i < 0 || i >= 12) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        monthLabels[i],
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                        color: barColor,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRankTile extends StatelessWidget {
  const _ProductRankTile({
    required this.name,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.icon,
    required this.iconColor,
  });

  final String name;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(name),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: trailingColor,
              ),
        ),
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  const _RecentSaleTile({
    required this.sale,
    required this.currencyCode,
    required this.trailing,
    required this.trailingColor,
  });

  final SaleRecord sale;
  final String currencyCode;
  final String trailing;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(sale.productName),
        subtitle: Text(
          '${sale.quantity} × ${formatMoney(sale.sellingPrice, currencyCode)} · '
          '${DateFormat.yMMMd().add_jm().format(sale.dateTime.toLocal())}',
        ),
        trailing: Text(
          trailing,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: trailingColor,
          ),
        ),
      ),
    );
  }
}
