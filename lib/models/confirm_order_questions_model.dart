class ConfirmOrderQuestion {
  final int questionId;
  final String question;

  ConfirmOrderQuestion({required this.questionId, required this.question});

  factory ConfirmOrderQuestion.fromJson(Map<String, dynamic> json) {
    return ConfirmOrderQuestion(
      questionId: json['questionId'] as int,
      question: (json['question'] ?? '').toString(),
    );
  }
}

class ConfirmOrderQuestionsData {
  final int orderId;
  final String disclaimer;
  final List<ConfirmOrderQuestion> questions;

  ConfirmOrderQuestionsData({
    required this.orderId,
    required this.disclaimer,
    required this.questions,
  });

  factory ConfirmOrderQuestionsData.fromJson(Map<String, dynamic> json) {
    return ConfirmOrderQuestionsData(
      orderId: json['orderId'] as int,
      disclaimer: (json['disclaimer'] ?? '').toString(),
      questions: (json['questions'] as List)
          .map((e) => ConfirmOrderQuestion.fromJson(e))
          .toList(),
    );
  }
}
