class ConfirmDeliveryItemModel {
  final int orderId;
  final int orderItemId;
  final String productCode;
  final String description;
  final String personToDeliver;

  ConfirmDeliveryItemModel({
    required this.orderId,
    required this.orderItemId,
    required this.productCode,
    required this.description,
    required this.personToDeliver,
  });

  factory ConfirmDeliveryItemModel.fromJson(Map<String, dynamic> json) {
    return ConfirmDeliveryItemModel(
      orderId: json['orderID'] as int,
      orderItemId: json['orderItemID'] as int,
      productCode: (json['product_Code'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      personToDeliver: (json['personToDeliver'] ?? '').toString(),
    );
  }
}
