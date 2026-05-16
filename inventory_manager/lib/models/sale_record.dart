class SaleRecord {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final double totalSaleAmount;
  final double profit;
  final DateTime dateTime;
  final String? soldBy;
  /// Optional sale note (customer, terms, description, etc.).
  final String? notes;

  SaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.totalSaleAmount,
    required this.profit,
    required this.dateTime,
    this.soldBy,
    this.notes,
  });

  /// Legacy field name used by older Firestore documents.
  double get totalPrice => totalSaleAmount;
}
