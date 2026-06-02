import '../core/api_client.dart';
import '../models/bay_manifesto_model.dart';
import '../models/confirm_delivery_item_model.dart';
import '../models/confirm_order_questions_model.dart';

class ConfirmOrderService {
  final _client = ApiClient();

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<List<BayManifestoModel>> fetchBayManifestos(DateTime date) async {
    final data = await _client.get(
      '/order/get-bay-manifesto-by-delivery-date',
      queryParams: {'DeliveryDate': _formatDate(date)},
    );
    return (data['data'] as List)
        .map((e) => BayManifestoModel.fromJson(e))
        .toList();
  }

  Future<List<ConfirmDeliveryItemModel>> fetchDeliveryItems(
      int manifestoId) async {
    final data = await _client.get(
      '/order/get-delivery-order-items-by-manifesto',
      queryParams: {'ManifestoID': manifestoId.toString()},
    );
    return (data['data'] as List)
        .map((e) => ConfirmDeliveryItemModel.fromJson(e))
        .toList();
  }

  Future<ConfirmOrderQuestionsData> fetchQuestions(int orderId) async {
    final data = await _client.get(
      '/order/get-questions-by-order',
      queryParams: {'OrderID': orderId.toString()},
    );
    return ConfirmOrderQuestionsData.fromJson(
        data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> saveConfirmation({
    required int orderId,
    required bool disclaimerAccepted,
    required String signatureBase64,
    required List<Map<String, dynamic>> answers,
  }) async {
    return await _client.post('/order/save-confirmation', {
      'orderId': orderId,
      'disclaimerAccepted': disclaimerAccepted,
      'signatureBase64': signatureBase64,
      'answers': answers,
    });
  }
}
