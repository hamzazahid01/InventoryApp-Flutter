import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/sales_history_filter.dart';

/// Period, category, and product filters — combinable for sales history.
class SalesHistoryFilterBar extends StatelessWidget {
  const SalesHistoryFilterBar({
    super.key,
    required this.filters,
    required this.products,
    required this.onChanged,
    this.onClearAll,
  });

  final SalesHistoryFilterState filters;
  final List<Product> products;
  final ValueChanged<SalesHistoryFilterState> onChanged;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = SalesHistoryFilter.categoriesFromProducts(products);
    final productsInCategory = List<Product>.from(
      SalesHistoryFilter.productsForCategory(products, filters.category),
    )..sort((a, b) => a.name.compareTo(b.name));

    final productValid = filters.productId == null ||
        productsInCategory.any((p) => p.id == filters.productId);

    final categoryValue = filters.category != null &&
            categories.contains(filters.category)
        ? filters.category
        : null;

    final productValue =
        productValid && filters.productId != null ? filters.productId : null;

    final selectedProductName = productValue == null
        ? null
        : products
            .where((p) => p.id == productValue)
            .map((p) => p.name)
            .firstOrNull;

    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter sales history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Combine period, category, and product',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            if (filters.hasActiveFilters) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear all'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Time period',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SalesHistoryPeriod.values.map((p) {
                  final selected = filters.period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.label),
                      selected: selected,
                      showCheckmark: true,
                      onSelected: (_) => onChanged(filters.copyWith(period: p)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FilterDropdown<String?>(
                    label: 'Category',
                    value: categoryValue,
                    hint: 'All categories',
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (cat) {
                      var next = filters.copyWith(
                        category: cat,
                        clearCategory: cat == null,
                      );
                      if (next.productId != null) {
                        final stillValid = SalesHistoryFilter.productsForCategory(
                          products,
                          cat,
                        ).any((p) => p.id == next.productId);
                        if (!stillValid) {
                          next = next.copyWith(clearProduct: true);
                        }
                      }
                      onChanged(next);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterDropdown<String?>(
                    label: 'Product',
                    value: productValue,
                    hint: 'All products',
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All products'),
                      ),
                      ...productsInCategory.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (id) => onChanged(
                      filters.copyWith(
                        productId: id,
                        clearProduct: id == null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (filters.hasActiveFilters) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (filters.period != SalesHistoryPeriod.total)
                    _ActiveChip(
                      label: filters.period.label,
                      onRemove: () => onChanged(
                        filters.copyWith(period: SalesHistoryPeriod.total),
                      ),
                    ),
                  if (filters.category != null)
                    _ActiveChip(
                      label: filters.category!,
                      onRemove: () => onChanged(filters.copyWith(clearCategory: true)),
                    ),
                  if (selectedProductName != null)
                    _ActiveChip(
                      label: selectedProductName,
                      onRemove: () => onChanged(filters.copyWith(clearProduct: true)),
                    ),
                ],
              ),
            ],
          ],
        ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: _valueInItems(value, items) ? value : null,
          isExpanded: true,
          hint: Text(hint, overflow: TextOverflow.ellipsis),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  bool _valueInItems(T? v, List<DropdownMenuItem<T>> items) {
    if (v == null) return items.any((i) => i.value == null);
    var count = 0;
    for (final item in items) {
      if (item.value == v) count++;
    }
    return count == 1;
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
    );
  }
}
