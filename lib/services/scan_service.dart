import '../core/api_client.dart';
import '../utils/app_preferences.dart';

class ScanService {
  final _client = ApiClient();

  /// Returns null on success, or the backend message on failure.
  Future<String?> sendPairedScan({
    required String uid,
    required String serialNumber,
    required String location,
    required int conditionId,
  }) async {
    try {
      final userId = await AppPreferences.getUserId();
      if (userId == null) return 'User session expired. Please log in again.';

      final data = await _client.post('/stockin/scan', {
        'uid': uid,
        'userUID': userId,
        'location': location,
        'conditionID': conditionId.toString(),
        'serialNumber': serialNumber,
      });

      if (data['success'] == true) return null;
      return (data['message'] as String?) ?? 'Scan failed';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
