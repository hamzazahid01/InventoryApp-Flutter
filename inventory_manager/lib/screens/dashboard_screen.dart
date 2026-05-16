import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import '../services/analytics_service.dart';
import '../utils/currency_format.dart';
import '../widgets/charts/sales_line_chart.dart';
import '../widgets/charts/stock_bar_chart.dart';
import '../widgets/metric_card.dart';
import '../widgets/sales_profit_summary_panel.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final cc = settings.currencyCode;

    if (!inv.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final dailyRev = AnalyticsService.dailyRevenueSeries(inv.sales, 14);
    final dailyProfit = AnalyticsService.dailyProfitSeries(inv.sales, 14);
    final sortedDays = dailyRev.keys.toList()..sort();
    final revSpots = <FlSpot>[
      for (var i = 0; i < sortedDays.length; i++)
        FlSpot(i.toDouble(), dailyRev[sortedDays[i]] ?? 0),
    ];
    final profitSpots = <FlSpot>[
      for (var i = 0; i < sortedDays.length; i++)
        FlSpot(i.toDouble(), dailyProfit[sortedDays[i]] ?? 0),
    ];

    final stockMap = AnalyticsService.stockByCategory(inv.products);
    final barLabels = stockMap.keys.toList();
    final barValues = barLabels.map((k) => stockMap[k]!).toList();

    final low = inv.lowStockProducts(settings.lowStockThreshold);
    final t = inv.salesToday();
    final w = inv.salesThisWeek();
    final m = inv.salesThisMonth();
    final topSelling = inv.topSellingProducts(limit: 5);

    return RefreshIndicator(
      onRefresh: () => context.read<InventoryNotifier>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final children = [
                MetricCard(
                  title: 'Total products',
                  value: '${inv.totalProductsCount}',
                  icon: Icons.inventory_2_outlined,
                ),
                MetricCard(
                  title: 'Stock remaining',
                  value: '${inv.totalStockAvailable}',
                  subtitle: 'units on hand',
                  icon: Icons.warehouse_outlined,
                  accentColor: Colors.teal,
                ),
                MetricCard(
                  title: 'Total revenue',
                  value: formatMoney(inv.totalRevenue, cc),
                  subtitle: 'from all sales',
                  icon: Icons.payments_outlined,
                  accentColor: Colors.blue.shade700,
                ),
                MetricCard(
                  title: 'Total profit',
                  value: formatMoney(inv.totalProfit, cc),
                  subtitle: 'selling price − cost',
                  icon: Icons.trending_up,
                  accentColor: Colors.green.shade700,
                ),
              ];
              if (wide) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in children)
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: c,
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    children[i],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Sales & profit summary'),
          SalesProfitSummaryPanel(
            currencyCode: cc,
            today: t,
            week: w,
            month: m,
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Top selling products'),
          if (topSelling.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No sales yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ),
            )
          else
            ...topSelling.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.local_fire_department_outlined, size: 20),
                    ),
                    title: Text(e.name),
                    subtitle: Text(
                      '${e.quantitySold} sold · Profit ${formatMoney(e.profit, cc)}',
                    ),
                    trailing: Text(
                      formatMoney(e.revenue, cc),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const SectionHeader(
            title: 'Low stock warning',
            action: Icon(Icons.warning_amber_rounded, color: Colors.orange),
          ),
          if (low.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No products below threshold (${settings.lowStockThreshold}).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
              ),
            )
          else
            ...low.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.15),
                      child: const Icon(Icons.priority_high, color: Colors.orange),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.stock} left · Cost ${formatMoney(p.costPrice, cc)}',
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SalesLineChart(
                spots: revSpots,
                currencyCode: cc,
                title: 'Revenue trend (14 days)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SalesLineChart(
                spots: profitSpots,
                currencyCode: cc,
                title: 'Profit trend (14 days)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StockBarChart(
                labels: barLabels,
                values: barValues,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
