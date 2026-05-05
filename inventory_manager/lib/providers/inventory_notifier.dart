import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../models/sale_record.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import 'auth_notifier.dart';

class InventoryNotifier extends ChangeNotifier {
  InventoryNotifier(this._firebase, this._auth);

  final FirebaseService _firebase;
  final AuthNotifier _auth;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<SaleRecord>>? _salesSub;

  List<Product> _products = [];
  List<SaleRecord> _sales = [];
  bool _receivedProducts = false;
  bool _receivedSales = false;

  List<Product> get products => List.unmodifiable(_products);
  List<SaleRecord> get sales => List.unmodifiable(_sales);

  bool get isLoaded => _receivedProducts && _receivedSales;

  void _listen() {
    _productsSub = _firebase.watchProducts().listen(
      (list) {
        _products = list;
        _receivedProducts = true;
        notifyListeners();
      },
      onError: (Object e, StackTrace _) {
        debugPrint('products stream: $e');
        _products = [];
        _receivedProducts = true;
        notifyListeners();
      },
    );
    _salesSub = _firebase.watchSales().listen(
      (list) {
        _sales = list;
        _receivedSales = true;
        notifyListeners();
      },
      onError: (Object e, StackTrace _) {
        debugPrint('sales stream: $e');
        _sales = [];
        _receivedSales = true;
        notifyListeners();
      },
    );
  }

  Future<void> load() async {
    await _productsSub?.cancel();
    await _salesSub?.cancel();
    _productsSub = null;
    _salesSub = null;
    _receivedProducts = false;
    _receivedSales = false;
    _products = [];
    _sales = [];
    notifyListeners();
    _listen();
  }

  @override
  void dispose() {
    unawaited(_productsSub?.cancel());
    unawaited(_salesSub?.cancel());
    super.dispose();
  }

  Product? productById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<({String productId, String? imageUrl, String? imageError})> addProduct({
    required String name,
    required double price,
    required int stock,
    String? category,
    XFile? image,
  }) async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot add products.');
    }
    return _firebase.createProduct(
      name: name,
      price: price,
      stock: stock,
      category: category,
      image: image,
    );
  }

  Future<void> updateProduct(
    Product updated, {
    XFile? newImage,
    bool removeImage = false,
  }) async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot edit products.');
    }
    await _firebase.updateProduct(
      updated,
      newImage: newImage,
      removeImage: removeImage,
    );
  }

  Future<void> deleteProduct(String id) async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot delete products.');
    }
    await _firebase.deleteProduct(id);
  }

  Future<String?> sellProduct({
    required String productId,
    required int quantity,
  }) async {
    if (!_auth.isAdmin) {
      return 'Read-only user: cannot record sales.';
    }
    return _firebase.sellProduct(productId: productId, quantity: quantity);
  }

  Future<String?> undoSale(String saleId) async {
    if (!_auth.isAdmin) {
      return 'Read-only user: cannot undo sales.';
    }
    return _firebase.undoSale(saleId);
  }

  int get totalProductsCount => _products.length;

  int get totalStockAvailable =>
      _products.fold<int>(0, (s, p) => s + p.stock);

  int get totalSoldUnits => _products.fold<int>(0, (s, p) => s + p.sold);

  double get totalRevenue => AnalyticsService.totalRevenue(_sales);

  List<Product> lowStockProducts(int threshold) {
    return _products.where((p) => p.stock < threshold).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
  }

  PeriodTotals salesToday() =>
      AnalyticsService.totalsForDay(_sales, DateTime.now());

  PeriodTotals salesThisWeek() =>
      AnalyticsService.totalsForWeek(_sales, DateTime.now());

  PeriodTotals salesThisMonth() =>
      AnalyticsService.totalsForMonth(_sales, DateTime.now());

  PeriodTotals salesThisYear() =>
      AnalyticsService.totalsForYear(_sales, DateTime.now());

  Future<void> resetAllData() async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot reset application data.');
    }
    await _firebase.resetAllFirestoreData();
  }

  Future<void> deleteSalesToday() async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot delete data.');
    }
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1));
    await _firebase.deleteSalesInRange(fromInclusive: from, toExclusive: to);
  }

  Future<void> deleteSalesLastWeek() async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot delete data.');
    }
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 7));
    await _firebase.deleteSalesInRange(fromInclusive: from, toExclusive: to);
  }

  Future<void> deleteSalesLastYear() async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot delete data.');
    }
    final to = DateTime.now();
    final from = DateTime(to.year - 1, to.month, to.day);
    await _firebase.deleteSalesInRange(fromInclusive: from, toExclusive: to);
  }

  Future<void> deleteAllSales() async {
    if (!_auth.isAdmin) {
      throw StateError('Read-only user: cannot delete data.');
    }
    await _firebase.deleteAllSales();
  }
}
