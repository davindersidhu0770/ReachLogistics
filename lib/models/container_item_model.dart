class ContainerItemModel {
  final String id;
  final String name;
  final int quantity;

  ContainerItemModel({
    required this.id,
    required this.name,
    required this.quantity,
  });

  factory ContainerItemModel.fromJson(Map<String, dynamic> json) {
    return ContainerItemModel(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
    );
  }
}