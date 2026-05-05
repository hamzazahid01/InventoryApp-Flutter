class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final int sold;
  /// Optional legacy field for UI grouping.
  final String? category;
  /// Remote URL (Firebase Storage download URL) when available.
  final String? imageUrl;
  /// Local file path fallback when Storage upload is unavailable/fails.
  ///
  /// Only valid on the same device; not shareable across devices.
  final String? localImagePath;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sold,
    this.category,
    this.imageUrl,
    this.localImagePath,
    required this.createdAt,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    int? sold,
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
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
      category: clearCategory ? null : (category ?? this.category),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePath ?? this.localImagePath),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
