import '../models/product.dart';
import '../models/sale_record.dart';

/// Time window for sales history list.
enum SalesHistoryPeriod {
  total,
  year,
  month,
  week,
  today;

  String get label => switch (this) {
        total => 'Total',
        year => 'This year',
        month => 'This month',
        week => 'This week',
        today => 'Today',
      };
}

class SalesHistoryFilterState {
  const SalesHistoryFilterState({
    this.period = SalesHistoryPeriod.total,
    this.productId,
    this.category,
  });

  final SalesHistoryPeriod period;
  /// `null` = all products.
  final String? productId;
  /// `null` = all categories.
  final String? category;

  bool get hasActiveFilters =>
      period != SalesHistoryPeriod.total ||
      productId != null ||
      category != null;

  int get activeFilterCount {
    var n = 0;
    if (period != SalesHistoryPeriod.total) n++;
    if (category != null) n++;
    if (productId != null) n++;
    return n;
  }

  SalesHistoryFilterState copyWith({
    SalesHistoryPeriod? period,
    String? productId,
    String? category,
    bool clearProduct = false,
    bool clearCategory = false,
  }) {
    return SalesHistoryFilterState(
      period: period ?? this.period,
      productId: clearProduct ? null : (productId ?? this.productId),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

}

class FilteredSalesSummary {
  const FilteredSalesSummary({
    required this.sales,
    required this.transactionCount,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
  });

  final List<SaleRecord> sales;
  final int transactionCount;
  final int unitsSold;
  final double revenue;
  final double profit;
}

class SalesHistoryFilter {
  static String _categoryKey(Product p) {
    final c = p.category?.trim();
    if (c == null || c.isEmpty) return 'Uncategorized';
    return c;
  }

  static Map<String, String> _productCategoryMap(List<Product> products) {
    return {for (final p in products) p.id: _categoryKey(p)};
  }

  static bool _matchesPeriod(SaleRecord sale, SalesHistoryPeriod period) {
    if (period == SalesHistoryPeriod.total) return true;
    final now = DateTime.now();
    final d = sale.dateTime;
    return switch (period) {
      SalesHistoryPeriod.today => _isSameDay(d, now),
      SalesHistoryPeriod.week => _inWeekContaining(d, now),
      SalesHistoryPeriod.month => d.year == now.year && d.month == now.month,
      SalesHistoryPeriod.year => d.year == now.year,
      SalesHistoryPeriod.total => true,
    };
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfWeekMonday(DateTime d) {
    final diff = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  static bool _inWeekContaining(DateTime sale, DateTime reference) {
    final start = _startOfWeekMonday(reference);
    final end = start.add(const Duration(days: 7));
    final x = DateTime(sale.year, sale.month, sale.day);
    return !x.isBefore(start) && x.isBefore(end);
  }

  static List<String> categoriesFromProducts(List<Product> products) {
    final set = <String>{};
    for (final p in products) {
      set.add(_categoryKey(p));
    }
    final list = set.toList()..sort();
    return list;
  }

  static List<Product> productsForCategory(
    List<Product> products,
    String? category,
  ) {
    if (category == null) return List<Product>.from(products);
    return products.where((p) => _categoryKey(p) == category).toList();
  }

  static FilteredSalesSummary apply({
    required List<SaleRecord> sales,
    required List<Product> products,
    required SalesHistoryFilterState filters,
  }) {
    final catByProduct = _productCategoryMap(products);
    final filtered = <SaleRecord>[];

    for (final s in sales) {
      if (!_matchesPeriod(s, filters.period)) continue;

      if (filters.productId != null && s.productId != filters.productId) {
        continue;
      }

      if (filters.category != null) {
        final saleCat = catByProduct[s.productId] ?? 'Uncategorized';
        if (saleCat != filters.category) continue;
      }

      filtered.add(s);
    }

    var units = 0;
    var revenue = 0.0;
    var profit = 0.0;
    for (final s in filtered) {
      units += s.quantity;
      revenue += s.totalSaleAmount;
      profit += s.profit;
    }

    return FilteredSalesSummary(
      sales: filtered,
      transactionCount: filtered.length,
      unitsSold: units,
      revenue: revenue,
      profit: profit,
    );
  }
}
