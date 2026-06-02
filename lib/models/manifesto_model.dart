class ManifestoModel {
  final int manifestoId;
  final String display;

  ManifestoModel({required this.manifestoId, required this.display});

  factory ManifestoModel.fromJson(Map<String, dynamic> json) {
    return ManifestoModel(
      manifestoId: json['manifestoID'] as int,
      display: (json['display'] ?? json['manifesto'] ?? '').toString(),
    );
  }
}
