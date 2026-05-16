class Product {
  final String id;
  final String name;
  /// Buying / cost price per unit (stored as `costPrice` in Firestore).
  final double costPrice;
  final int stock;
  final int sold;
  final double totalRevenue;
  final double totalProfit;
  /// Optional legacy field for UI grouping.
  final String? category;
  /// Remote URL (Firebase Storage download URL) when available.
  final String? imageUrl;
  /// Local file path fallback when Storage upload is unavailable/fails.
  final String? localImagePath;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.stock,
    required this.sold,
    this.totalRevenue = 0,
    this.totalProfit = 0,
    this.category,
    this.imageUrl,
    this.localImagePath,
    required this.createdAt,
  });

  /// Backward-compatible alias for cost price.
  double get price => costPrice;

  int get currentStock => stock;

  int get soldQuantity => sold;

  Product copyWith({
    String? id,
    String? name,
    double? costPrice,
    int? stock,
    int? sold,
    double? totalRevenue,
    double? totalProfit,
    String? category,
    String? imageUrl,
    String? localImagePath,
    DateTime? createdAt,
    bool clearCategory = false,
    bool clearImageUrl = false,
    bool clearLocalImagePath = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProfit: totalProfit ?? this.totalProfit,
      category: clearCategory ? null : (category ?? this.category),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePath ?? this.localImagePath),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
