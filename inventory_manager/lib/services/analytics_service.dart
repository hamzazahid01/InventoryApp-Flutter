import '../models/product.dart';
import '../models/sale_record.dart';

class PeriodTotals {
  final double revenue;
  final int unitsSold;

  const PeriodTotals({required this.revenue, required this.unitsSold});
}

class ProductPerformance {
  final String productId;
  final String name;
  final int quantitySold;
  final double revenue;

  const ProductPerformance({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
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
    return sales.fold<double>(0, (s, r) => s + r.totalPrice);
  }

  static PeriodTotals totalsForDay(List<SaleRecord> sales, DateTime day) {
    double rev = 0;
    int units = 0;
    for (final r in sales) {
      if (_isSameDay(r.dateTime, day)) {
        rev += r.totalPrice;
        units += r.quantity;
      }
    }
    return PeriodTotals(revenue: rev, unitsSold: units);
  }

  static PeriodTotals totalsForWeek(List<SaleRecord> sales, DateTime reference) {
    double rev = 0;
    int units = 0;
    for (final r in sales) {
      if (_inWeekContaining(r.dateTime, reference)) {
        rev += r.totalPrice;
        units += r.quantity;
      }
    }
    return PeriodTotals(revenue: rev, unitsSold: units);
  }

  static PeriodTotals totalsForMonth(List<SaleRecord> sales, DateTime reference) {
    double rev = 0;
    int units = 0;
    for (final r in sales) {
      if (_inMonth(r.dateTime, reference)) {
        rev += r.totalPrice;
        units += r.quantity;
      }
    }
    return PeriodTotals(revenue: rev, unitsSold: units);
  }

  static PeriodTotals totalsForYear(List<SaleRecord> sales, DateTime reference) {
    double rev = 0;
    int units = 0;
    for (final r in sales) {
      if (_inYear(r.dateTime, reference)) {
        rev += r.totalPrice;
        units += r.quantity;
      }
    }
    return PeriodTotals(revenue: rev, unitsSold: units);
  }

  /// Last [days] calendar days including today; bucket by date key yyyy-MM-dd.
  static Map<DateTime, double> dailyRevenueSeries(
    List<SaleRecord> sales,
    int days,
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
        map[key] = (map[key] ?? 0) + r.totalPrice;
      }
    }
    return map;
  }

  static Map<int, double> monthlyRevenueYear(List<SaleRecord> sales, int year) {
    final map = <int, double>{};
    for (var m = 1; m <= 12; m++) {
      map[m] = 0;
    }
    for (final r in sales) {
      if (r.dateTime.year == year) {
        map[r.dateTime.month] =
            (map[r.dateTime.month] ?? 0) + r.totalPrice;
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
          revenue: r.totalPrice,
        );
      } else {
        byId[r.productId] = ProductPerformance(
          productId: r.productId,
          name: existing.name,
          quantitySold: existing.quantitySold + r.quantity,
          revenue: existing.revenue + r.totalPrice,
        );
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return list;
  }

  /// Products with zero sales in [sales], or bottom by sold units from catalog.
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

  /// Stock grouped by category (null → "Uncategorized").
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
