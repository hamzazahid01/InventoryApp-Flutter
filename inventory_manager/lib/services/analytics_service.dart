import '../models/product.dart';
import '../models/sale_record.dart';

class PeriodTotals {
  final double revenue;
  final double profit;
  final int unitsSold;

  const PeriodTotals({
    required this.revenue,
    required this.profit,
    required this.unitsSold,
  });
}

class ProductPerformance {
  final String productId;
  final String name;
  final int quantitySold;
  final double revenue;
  final double profit;

  const ProductPerformance({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
    required this.profit,
  });
}

class AnalyticsService {
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfWeekMonday(DateTime d) {
    final weekday = d.weekday;
    final diff = weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  static bool _inWeekContaining(DateTime sale, DateTime reference) {
    final start = _startOfWeekMonday(reference);
    final end = start.add(const Duration(days: 7));
    final x = DateTime(sale.year, sale.month, sale.day);
    return !x.isBefore(start) && x.isBefore(end);
  }

  static bool _inMonth(DateTime sale, DateTime reference) {
    return sale.year == reference.year && sale.month == reference.month;
  }

  static bool _inYear(DateTime sale, DateTime reference) {
    return sale.year == reference.year;
  }

  static double totalRevenue(List<SaleRecord> sales) {
    return sales.fold<double>(0, (s, r) => s + r.totalSaleAmount);
  }

  static double totalProfit(List<SaleRecord> sales) {
    return sales.fold<double>(0, (s, r) => s + r.profit);
  }

  static PeriodTotals _totalsFor(
    List<SaleRecord> sales,
    bool Function(SaleRecord r) include,
  ) {
    double rev = 0;
    double profit = 0;
    int units = 0;
    for (final r in sales) {
      if (include(r)) {
        rev += r.totalSaleAmount;
        profit += r.profit;
        units += r.quantity;
      }
    }
    return PeriodTotals(revenue: rev, profit: profit, unitsSold: units);
  }

  static PeriodTotals totalsForDay(List<SaleRecord> sales, DateTime day) {
    return _totalsFor(sales, (r) => _isSameDay(r.dateTime, day));
  }

  static PeriodTotals totalsForWeek(List<SaleRecord> sales, DateTime reference) {
    return _totalsFor(
      sales,
      (r) => _inWeekContaining(r.dateTime, reference),
    );
  }

  static PeriodTotals totalsForMonth(List<SaleRecord> sales, DateTime reference) {
    return _totalsFor(sales, (r) => _inMonth(r.dateTime, reference));
  }

  static PeriodTotals totalsForYear(List<SaleRecord> sales, DateTime reference) {
    return _totalsFor(sales, (r) => _inYear(r.dateTime, reference));
  }

  static Map<DateTime, double> dailyRevenueSeries(
    List<SaleRecord> sales,
    int days,
  ) {
    return _dailySeries(sales, days, (r) => r.totalSaleAmount);
  }

  static Map<DateTime, double> dailyProfitSeries(
    List<SaleRecord> sales,
    int days,
  ) {
    return _dailySeries(sales, days, (r) => r.profit);
  }

  static Map<DateTime, double> _dailySeries(
    List<SaleRecord> sales,
    int days,
    double Function(SaleRecord) valueOf,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = <DateTime, double>{};
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      map[DateTime(d.year, d.month, d.day)] = 0;
    }
    for (final r in sales) {
      final key = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + valueOf(r);
      }
    }
    return map;
  }

  static Map<int, double> monthlyRevenueYear(List<SaleRecord> sales, int year) {
    return _monthlyYear(sales, year, (r) => r.totalSaleAmount);
  }

  static Map<int, double> monthlyProfitYear(List<SaleRecord> sales, int year) {
    return _monthlyYear(sales, year, (r) => r.profit);
  }

  static Map<int, double> _monthlyYear(
    List<SaleRecord> sales,
    int year,
    double Function(SaleRecord) valueOf,
  ) {
    final map = <int, double>{};
    for (var m = 1; m <= 12; m++) {
      map[m] = 0;
    }
    for (final r in sales) {
      if (r.dateTime.year == year) {
        map[r.dateTime.month] = (map[r.dateTime.month] ?? 0) + valueOf(r);
      }
    }
    return map;
  }

  static List<ProductPerformance> productPerformance(List<SaleRecord> sales) {
    final byId = <String, ProductPerformance>{};
    for (final r in sales) {
      final existing = byId[r.productId];
      if (existing == null) {
        byId[r.productId] = ProductPerformance(
          productId: r.productId,
          name: r.productName,
          quantitySold: r.quantity,
          revenue: r.totalSaleAmount,
          profit: r.profit,
        );
      } else {
        byId[r.productId] = ProductPerformance(
          productId: r.productId,
          name: existing.name,
          quantitySold: existing.quantitySold + r.quantity,
          revenue: existing.revenue + r.totalSaleAmount,
          profit: existing.profit + r.profit,
        );
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return list;
  }

  static List<ProductPerformance> topRevenueProducts(
    List<SaleRecord> sales, {
    int limit = 8,
  }) {
    final list = List<ProductPerformance>.from(productPerformance(sales))
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(limit).toList();
  }

  static List<ProductPerformance> topProfitProducts(
    List<SaleRecord> sales, {
    int limit = 8,
  }) {
    final list = List<ProductPerformance>.from(productPerformance(sales))
      ..sort((a, b) => b.profit.compareTo(a.profit));
    return list.take(limit).toList();
  }

  static List<SaleRecord> recentSales(
    List<SaleRecord> sales, {
    int limit = 12,
  }) {
    return sales.take(limit).toList();
  }

  static List<SaleRecord> recentProfitableSales(
    List<SaleRecord> sales, {
    int limit = 12,
  }) {
    return sales.where((s) => s.profit > 0).take(limit).toList();
  }

  static List<Product> lowPerformingProducts(
    List<Product> products,
    List<SaleRecord> sales, {
    int limit = 8,
  }) {
    final perf = {
      for (final p in products) p.id: 0,
    };
    for (final r in sales) {
      perf[r.productId] = (perf[r.productId] ?? 0) + r.quantity;
    }
    final sorted = [...products]
      ..sort((a, b) {
        final qa = perf[a.id] ?? 0;
        final qb = perf[b.id] ?? 0;
        return qa.compareTo(qb);
      });
    return sorted.take(limit).toList();
  }

  static Map<String, int> stockByCategory(List<Product> products) {
    final map = <String, int>{};
    for (final p in products) {
      final key = (p.category == null || p.category!.trim().isEmpty)
          ? 'Uncategorized'
          : p.category!.trim();
      map[key] = (map[key] ?? 0) + p.stock;
    }
    return map;
  }
}
