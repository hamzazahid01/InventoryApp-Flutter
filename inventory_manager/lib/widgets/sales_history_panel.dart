import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../models/sale_record.dart';
import '../utils/currency_format.dart';
import '../utils/sales_history_filter.dart';
import 'sales_history_filter_bar.dart';

/// Full-screen sales history with filters in a bottom sheet.
class SalesHistoryPanel extends StatelessWidget {
  const SalesHistoryPanel({
    super.key,
    required this.products,
    required this.allSalesCount,
    required this.summary,
    required this.effectiveFilters,
    required this.currencyCode,
    required this.isAdmin,
    required this.onFiltersChanged,
    required this.onClearFilters,
    required this.onUndoSale,
  });

  final List<Product> products;
  final int allSalesCount;
  final FilteredSalesSummary summary;
  final SalesHistoryFilterState effectiveFilters;
  final String currencyCode;
  final bool isAdmin;
  final ValueChanged<SalesHistoryFilterState> onFiltersChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function(SaleRecord sale) onUndoSale;

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SalesHistoryFilterBar(
                filters: effectiveFilters,
                products: products,
                onChanged: onFiltersChanged,
                onClearAll: () {
                  onClearFilters();
                  Navigator.pop(ctx);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat.yMMMd().add_jm();
    final hasFilters = effectiveFilters.hasActiveFilters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sales history',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasFilters
                                  ? '${summary.transactionCount} of $allSalesCount transactions'
                                  : '$allSalesCount transactions',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Badge(
                        isLabelVisible: hasFilters,
                        label: Text('${effectiveFilters.activeFilterCount}'),
                        child: FilledButton.tonalIcon(
                          onPressed: () => _openFilters(context),
                          icon: const Icon(Icons.tune, size: 20),
                          label: const Text('Filters'),
                        ),
                      ),
                    ],
                  ),
                  if (hasFilters) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (effectiveFilters.period != SalesHistoryPeriod.total)
                          _FilterTag(
                            label: effectiveFilters.period.label,
                            onTap: () => _openFilters(context),
                          ),
                        if (effectiveFilters.category != null)
                          _FilterTag(
                            label: effectiveFilters.category!,
                            onTap: () => _openFilters(context),
                          ),
                        if (effectiveFilters.productId != null)
                          _FilterTag(
                            label: products
                                    .where((p) => p.id == effectiveFilters.productId)
                                    .map((p) => p.name)
                                    .firstOrNull ??
                                'Product',
                            onTap: () => _openFilters(context),
                          ),
                        ActionChip(
                          label: const Text('Clear'),
                          avatar: const Icon(Icons.close, size: 16),
                          onPressed: onClearFilters,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SummaryCell(
                        label: 'Units',
                        value: '${summary.unitsSold}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _SummaryCell(
                        label: 'Revenue',
                        value: formatMoney(summary.revenue, currencyCode),
                        icon: Icons.payments_outlined,
                      ),
                      _SummaryCell(
                        label: 'Profit',
                        value: formatMoney(summary.profit, currencyCode),
                        icon: Icons.trending_up,
                        valueColor: summary.profit >= 0
                            ? const Color(0xFF15803D)
                            : cs.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: summary.sales.isEmpty
              ? _EmptyHistory(
                  allSalesEmpty: allSalesCount == 0,
                  hasFilters: hasFilters,
                  onClearFilters: onClearFilters,
                  onOpenFilters: () => _openFilters(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: summary.sales.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = summary.sales[i];
                    return _SaleHistoryCard(
                      sale: s,
                      currencyCode: currencyCode,
                      dateFormatted: df.format(s.dateTime.toLocal()),
                      isAdmin: isAdmin,
                      onUndo: () => onUndoSale(s),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.85)),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  const _SaleHistoryCard({
    required this.sale,
    required this.currencyCode,
    required this.dateFormatted,
    required this.isAdmin,
    required this.onUndo,
  });

  final SaleRecord sale;
  final String currencyCode;
  final String dateFormatted;
  final bool isAdmin;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitUp = sale.profit >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (profitUp ? Colors.green : cs.error)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sale.quantity}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.productName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sale.quantity} × ${formatMoney(sale.sellingPrice, currencyCode)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sale.notes!.trim(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(sale.totalSaleAmount, currencyCode),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Profit ${formatMoney(sale.profit, currencyCode)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: profitUp
                            ? const Color(0xFF15803D)
                            : cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (isAdmin)
                  IconButton(
                    tooltip: 'Undo sale',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onUndo,
                    icon: Icon(Icons.undo, size: 20, color: cs.primary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.allSalesEmpty,
    required this.hasFilters,
    required this.onClearFilters,
    required this.onOpenFilters,
  });

  final bool allSalesEmpty;
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              allSalesEmpty
                  ? 'No sales recorded yet'
                  : 'No sales match your filters',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              allSalesEmpty
                  ? 'Record a sale from the Sell tab.'
                  : 'Try different period, category, or product.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            if (!allSalesEmpty && hasFilters) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: onClearFilters,
                    child: const Text('Clear filters'),
                  ),
                  FilledButton.tonal(
                    onPressed: onOpenFilters,
                    child: const Text('Adjust filters'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
