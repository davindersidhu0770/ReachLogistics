class BayModel {
  final String bayNumber;

  BayModel({required this.bayNumber});

  factory BayModel.fromJson(dynamic json) {
    if (json is String) return BayModel(bayNumber: json);
    return BayModel(
      bayNumber: (json['bayNumber'] ?? json['display'] ?? '').toString(),
    );
  }
}
