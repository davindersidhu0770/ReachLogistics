class ConditionModel {
  final int uid;
  final String condition;

  ConditionModel({
    required this.uid,
    required this.condition,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      uid: json['uid'],
      condition: json['condition'],
    );
  }
}