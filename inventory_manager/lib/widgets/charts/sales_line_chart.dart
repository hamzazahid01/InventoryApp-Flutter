import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/currency_format.dart';

class SalesLineChart extends StatelessWidget {
  const SalesLineChart({
    super.key,
    required this.spots,
    required this.currencyCode,
    this.title = 'Sales trend',
    this.xAxisLabels,
  });

  /// X: index 0..n-1, Y: revenue for that day bucket (same order as labels).
  final List<FlSpot> spots;
  final String currencyCode;
  final String title;

  /// Optional label per spot index; use empty strings to hide crowded ticks.
  final List<String>? xAxisLabels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (spots.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No sales data yet',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    final niceMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    final rawLabels = xAxisLabels;
    final List<String> bottomLabels;
    if (rawLabels != null &&
        rawLabels.length == spots.length &&
        rawLabels.any((t) => t.isNotEmpty)) {
      bottomLabels = rawLabels;
    } else {
      bottomLabels = const [];
    }
    final showBottom = bottomLabels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: niceMax > 5 ? niceMax / 4 : null,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: cs.outline.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      if (value > meta.max || value < meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}k'
                              : value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showBottom,
                    reservedSize: showBottom ? 26 : 0,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (!showBottom) {
                        return const SizedBox.shrink();
                      }
                      final i = value.round();
                      if (i < 0 || i >= bottomLabels.length) {
                        return const SizedBox.shrink();
                      }
                      final t = bottomLabels[i];
                      if (t.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          t,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
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
              minX: spots.first.x,
              maxX: spots.last.x,
              minY: 0,
              maxY: niceMax,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      final i = s.x.round();
                      final dayHint = showBottom &&
                              i >= 0 &&
                              i < bottomLabels.length &&
                              bottomLabels[i].isNotEmpty
                          ? '${bottomLabels[i]}\n'
                          : '';
                      return LineTooltipItem(
                        '$dayHint${formatMoney(s.y, currencyCode)}',
                        TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  color: cs.primary,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: cs.primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
