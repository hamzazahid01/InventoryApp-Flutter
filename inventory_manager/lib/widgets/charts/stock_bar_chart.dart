import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StockBarChart extends StatelessWidget {
  const StockBarChart({
    super.key,
    required this.labels,
    required this.values,
    this.title = 'Stock by category',
  });

  final List<String> labels;
  final List<int> values;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (labels.isEmpty || values.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Add products to see distribution',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    final maxV = values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxV <= 0 ? 1.0 : maxV.toDouble() * 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: cs.outline.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      final text = labels[i].length > 8
                          ? '${labels[i].substring(0, 8)}…'
                          : labels[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value > meta.max || value < meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.45),
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
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i].toDouble(),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        color: Color.lerp(cs.primary, cs.tertiary, i / values.length) ??
                            cs.primary,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
