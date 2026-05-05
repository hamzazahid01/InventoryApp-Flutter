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

    final daily = AnalyticsService.dailyRevenueSeries(inv.sales, 14);
    final sortedDays = daily.keys.toList()..sort();
    final spots = <FlSpot>[
      for (var i = 0; i < sortedDays.length; i++)
        FlSpot(i.toDouble(), daily[sortedDays[i]] ?? 0),
    ];

    final stockMap = AnalyticsService.stockByCategory(inv.products);
    final barLabels = stockMap.keys.toList();
    final barValues = barLabels.map((k) => stockMap[k]!).toList();

    final low = inv.lowStockProducts(settings.lowStockThreshold);
    final t = inv.salesToday();
    final w = inv.salesThisWeek();
    final m = inv.salesThisMonth();
    final y = inv.salesThisYear();

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
                  title: 'Stock available',
                  value: '${inv.totalStockAvailable}',
                  subtitle: 'units on hand',
                  icon: Icons.warehouse_outlined,
                  accentColor: Colors.teal,
                ),
                MetricCard(
                  title: 'Items sold',
                  value: '${inv.totalSoldUnits}',
                  subtitle: 'lifetime',
                  icon: Icons.shopping_bag_outlined,
                  accentColor: Colors.deepPurple,
                ),
                MetricCard(
                  title: 'Total revenue',
                  value: formatMoney(inv.totalRevenue, cc),
                  subtitle: 'from recorded sales',
                  icon: Icons.payments_outlined,
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
          const SectionHeader(title: 'Sales summary'),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              Widget tile(String label, double rev, int units) {
                return Card(
                  child: ListTile(
                    title: Text(label),
                    subtitle: Text('$units units · ${formatMoney(rev, cc)}'),
                  ),
                );
              }

              final tiles = [
                tile('Today', t.revenue, t.unitsSold),
                tile('This week', w.revenue, w.unitsSold),
                tile('This month', m.revenue, m.unitsSold),
                tile('This year', y.revenue, y.unitsSold),
              ];
              if (wide) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final t in tiles)
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: t,
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    tiles[i],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Low stock alerts',
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
                      '${p.stock} left · ${formatMoney(p.price, cc)}',
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
                spots: spots,
                currencyCode: cc,
                title: 'Sales trend (14 days)',
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
