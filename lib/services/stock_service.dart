import '../core/api_client.dart';
import '../models/conditions_model.dart';
import '../models/scan_action_result.dart';
import '../models/stock_lookup_result.dart';

class StockService {
  final _client = ApiClient();

  Future<List<ConditionModel>> fetchConditions() async {
    final data = await _client.get('/stock/get-conditions');
    return (data['data'] as List)
        .map((e) => ConditionModel.fromJson(e))
        .toList();
  }

  Future<List<StockLookupResultModel>> lookup(String input) async {
    final data = await _client.get(
      '/stock/lookup',
      queryParams: {'input': input},
    );
    return (data['data'] as List)
        .map((e) => StockLookupResultModel.fromJson(e))
        .toList();
  }

  Future<ScanActionResult> scan({
    required String uid,
    required int conditionId,
  }) async {
    try {
      final response = await _client.post('/stock/scan', {
        'uid': uid,
        'conditionID': conditionId,
      });
      return ScanActionResult.fromResponse(response);
    } catch (e) {
      return ScanActionResult.error(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }
}