import '../core/api_client.dart';
import '../models/bay_manifesto_model.dart';
import '../models/bay_model.dart';
import '../models/manifesto_model.dart';
import '../models/order_item_model.dart';
import '../models/picking_scan_result.dart';

class PickingService {
  final _client = ApiClient();

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<List<BayManifestoModel>> fetchBayManifestos(DateTime date) async {
    final data = await _client.get(
      '/picking/get-bay-manifesto-by-pick-date',
      queryParams: {'PickDate': _formatDate(date)},
    );
    return (data['data'] as List)
        .map((e) => BayManifestoModel.fromJson(e))
        .toList();
  }

  Future<List<BayModel>> fetchBayNumbers(DateTime date) async {
    final data = await _client.get(
      '/picking/get-bay-numbers-by-pick-date',
      queryParams: {'PickDate': _formatDate(date)},
    );
    return (data['data'] as List).map((e) => BayModel.fromJson(e)).toList();
  }

  Future<List<ManifestoModel>> fetchManifestos(
      DateTime date, String bayNumber) async {
    final data = await _client.get(
      '/picking/get-manifesto-by-bay_number',
      queryParams: {
        'PickDate': _formatDate(date),
        'BayNumber': bayNumber,
      },
    );
    return (data['data'] as List)
        .map((e) => ManifestoModel.fromJson(e))
        .toList();
  }

  Future<List<OrderItemModel>> fetchOrderItems(int manifestoId) async {
    final data = await _client.get(
      '/picking/get-order-items-by-manifesto',
      queryParams: {'ManifestoID': manifestoId.toString()},
    );
    return (data['data'] as List)
        .map((e) => OrderItemModel.fromJson(e))
        .toList();
  }

  Future<PickingScanResult> scanFirst(int orderItemId) async {
    try {
      final response = await _client.post('/picking/scan', {
        'orderItemID': orderItemId,
      });
      return PickingScanResult.fromResponse(response);
    } catch (e) {
      return PickingScanResult.error(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<PickingScanResult> scanSecond(int orderItemId, String uid) async {
    try {
      final response = await _client.post('/picking/scan', {
        'orderItemID': orderItemId,
        'uid': uid,
      });
      return PickingScanResult.fromResponse(response);
    } catch (e) {
      return PickingScanResult.error(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
