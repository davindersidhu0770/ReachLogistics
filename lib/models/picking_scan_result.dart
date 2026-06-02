class PickingScanResult {
  final bool success;
  final bool isBulk;
  final bool isCompleted;
  final String message;

  PickingScanResult({
    required this.success,
    required this.isBulk,
    required this.isCompleted,
    required this.message,
  });

  factory PickingScanResult.fromResponse(Map<String, dynamic> response) {
    final success = response['success'] == true;
    final data = response['data'] as Map<String, dynamic>?;

    return PickingScanResult(
      success: success,
      isBulk: data?['isBulk'] as bool? ?? false,
      isCompleted: data?['isCompleted'] as bool? ?? false,
      message: (data?['message'] as String?)?.isNotEmpty == true
          ? data!['message'] as String
          : (response['message'] as String?) ?? (success ? 'Success' : 'Scan failed'),
    );
  }

  factory PickingScanResult.error(String message) => PickingScanResult(
        success: false,
        isBulk: false,
        isCompleted: false,
        message: message,
      );
}
