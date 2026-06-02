class VanLoadingScanResult {
  final bool success;
  final bool isCompleted;
  final String message;

  VanLoadingScanResult({
    required this.success,
    required this.isCompleted,
    required this.message,
  });

  factory VanLoadingScanResult.fromResponse(Map<String, dynamic> response) {
    final success = response['success'] == true;
    final data = response['data'] as Map<String, dynamic>?;

    return VanLoadingScanResult(
      success: success,
      isCompleted: data?['isCompleted'] as bool? ?? success,
      message: (data?['message'] as String?)?.isNotEmpty == true
          ? data!['message'] as String
          : (response['message'] as String?) ??
              (success ? 'Success' : 'Scan failed'),
    );
  }

  factory VanLoadingScanResult.error(String message) => VanLoadingScanResult(
        success: false,
        isCompleted: false,
        message: message,
      );
}