class BayManifestoModel {
  final String bayNumber;
  final int manifestoId;
  final String display;

  BayManifestoModel({
    required this.bayNumber,
    required this.manifestoId,
    required this.display,
  });

  factory BayManifestoModel.fromJson(Map<String, dynamic> json) {
    return BayManifestoModel(
      bayNumber: (json['bayNumber'] ?? '').toString(),
      manifestoId: json['manifestoID'] as int,
      display: (json['bayManifestoDisplay'] ?? '').toString(),
    );
  }
}