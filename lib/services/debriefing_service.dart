import '../core/api_client.dart';
import '../models/bay_manifesto_model.dart';
import '../models/order_item_model.dart';
import '../models/van_loading_scan_result.dart';

class DebriefingService {
  final _client = ApiClient();

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<List<BayManifestoModel>> fetchBayManifestos(DateTime date) async {
    final data = await _client.get(
      '/reverse-picking/get-bay-manifesto-by-pick-date',
      queryParams: {'PickDate': _formatDate(date)},
    );
    return (data['data'] as List)
        .map((e) => BayManifestoModel.fromJson(e))
        .toList();
  }

  Future<List<OrderItemModel>> fetchOrderItems(int manifestoId) async {
    final data = await _client.get(
      '/reverse-picking/get-order-items-by-manifesto',
      queryParams: {'ManifestoID': manifestoId.toString()},
    );
    return (data['data'] as List)
        .map((e) => OrderItemModel.fromJson(e))
        .toList();
  }

  Future<VanLoadingScanResult> scan(int orderItemId) async {
    try {
      final response = await _client.post('/reverse-picking/scan', {
        'orderItemID': orderItemId,
      });
      return VanLoadingScanResult.fromResponse(response);
    } catch (e) {
      return VanLoadingScanResult.error(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> printLabel(int manifestoId) async {
    try {
      final data = await _client.get(
        '/reverse-picking/print-label',
        queryParams: {'ManifestoID': manifestoId.toString()},
      );
      if (data['success'] == true) return null; // null = success
      return (data['message'] as String?) ?? 'Print failed';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
