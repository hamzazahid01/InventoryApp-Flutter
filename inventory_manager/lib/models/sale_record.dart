class SaleRecord {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double totalPrice;
  final DateTime dateTime;

  SaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.dateTime,
  });
}
