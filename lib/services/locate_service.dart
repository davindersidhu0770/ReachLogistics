import '../core/api_client.dart';
import '../models/location_model.dart';
import '../models/scan_action_result.dart';

class LocateService {
  final _client = ApiClient();

  Future<List<LocationModel>> fetchLocations() async {
    final data = await _client.get('/locate/get-locations');
    return (data['data'] as List)
        .map((e) => LocationModel.fromJson(e))
        .toList();
  }

  Future<ScanActionResult> scan({
    required String uid,
    required String location,
  }) async {
    try {
      final response = await _client.post('/locate/scan', {
        'uid': uid,
        'location': location,
      });
      return ScanActionResult.fromResponse(response);
    } catch (e) {
      return ScanActionResult.error(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }
}