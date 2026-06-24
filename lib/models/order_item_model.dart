class OrderItemModel {
  final int orderItemId;
  final String description;
  final int quantity;
  final String productCode;
  final String location;

  OrderItemModel(
      {required this.orderItemId,
      required this.description,
      required this.quantity,
      required this.productCode,
      required this.location});

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      orderItemId: json['orderItemID'] as int,
      description: (json['description'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      productCode: (json['product_Code'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
    );
  }
}
