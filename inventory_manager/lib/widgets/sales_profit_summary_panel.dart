import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../utils/currency_format.dart';

/// Unified period comparison for dashboard — revenue & profit by window.
class SalesProfitSummaryPanel extends StatelessWidget {
  const SalesProfitSummaryPanel({
    super.key,
    required this.currencyCode,
    required this.today,
    required this.week,
    required this.month,
  });

  final String currencyCode;
  final PeriodTotals today;
  final PeriodTotals week;
  final PeriodTotals month;

  static const _rows = [
    _PeriodRowData(
      label: 'Today',
      icon: Icons.today_outlined,
    ),
    _PeriodRowData(
      label: 'This week',
      icon: Icons.date_range_outlined,
    ),
    _PeriodRowData(
      label: 'This month',
      icon: Icons.calendar_month_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totals = [today, week, month];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Period breakdown',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          ...List.generate(3, (i) {
            final meta = _rows[i];
            final data = totals[i];
            final isLast = i == 2;
            return Column(
              children: [
                _PeriodDataRow(
                  label: meta.label,
                  icon: meta.icon,
                  data: data,
                  currencyCode: currencyCode,
                  highlighted: i == 0,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PeriodRowData {
  const _PeriodRowData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _PeriodDataRow extends StatelessWidget {
  const _PeriodDataRow({
    required this.label,
    required this.icon,
    required this.data,
    required this.currencyCode,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final PeriodTotals data;
  final String currencyCode;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitPositive = data.profit >= 0;

    return Material(
      color: highlighted
          ? cs.primaryContainer.withValues(alpha: 0.22)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (highlighted ? cs.primary : cs.surfaceContainerHighest)
                        .withValues(alpha: highlighted ? 0.18 : 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: highlighted
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: 'Units',
                    value: '${data.unitsSold}',
                  ),
                ),
                Expanded(
                  child: _MetricCell(
                    label: 'Revenue',
                    value: formatMoney(data.revenue, currencyCode),
                    alignEnd: true,
                  ),
                ),
                Expanded(
                  child: _MetricCell(
                    label: 'Profit',
                    value: formatMoney(data.profit, currencyCode),
                    alignEnd: true,
                    valueColor: profitPositive
                        ? const Color(0xFF15803D)
                        : cs.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        );

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: muted),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
