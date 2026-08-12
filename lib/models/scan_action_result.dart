/// Generic result for simple scan endpoints that just report success/failure
/// with a message (e.g. /locate/scan, /stock/scan) — no extra payload.
class ScanActionResult {
  final bool success;
  final String message;

  ScanActionResult({required this.success, required this.message});

  factory ScanActionResult.fromResponse(Map<String, dynamic> response) {
    final success = response['success'] == true;
    return ScanActionResult(
      success: success,
      message: (response['message'] as String?) ??
          (success ? 'Success' : 'Scan failed'),
    );
  }

  factory ScanActionResult.error(String message) =>
      ScanActionResult(success: false, message: message);
}