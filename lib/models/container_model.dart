class ContainerModel {
  final String id;
  final String containerNumber;
  final String status;
  final DateTime date;

  ContainerModel({
    required this.id,
    required this.containerNumber,
    required this.status,
    required this.date,
  });

  // API JSON parsing ready
  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      id: json['id'],
      containerNumber: json['containerNumber'],
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }
}