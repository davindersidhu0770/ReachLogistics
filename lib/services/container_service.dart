import '../core/api_client.dart';
import '../models/conditions_model.dart';
import '../models/container_model.dart';
import '../models/container_item_model.dart';
import '../models/location_model.dart';

class ContainerService {
  final _client = ApiClient();

  Future<List<ContainerModel>> fetchContainers(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final data = await _client.get(
      '/stockin/get-containers-by-date',
      queryParams: {'date': formattedDate},
    );

    return (data["data"] as List).map((e) {
      return ContainerModel(
        id: e["containerRef"],
        containerNumber: e["display"],
        status: e["status"],
        date: date,
      );
    }).toList();
  }

  Future<List<ContainerItemModel>> fetchContainerItems(
    DateTime date,
    String containerRef,
    int conditionId,
  ) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final data = await _client.get(
      '/stockin/get-products-by-container',
      queryParams: {
        'date': formattedDate,
        'containerRef': containerRef,
        'conditionID': conditionId.toString(),
      },
    );

    return (data["data"] as List).map((e) {
      return ContainerItemModel(
        id: e["productID"].toString(),
        name: e["description"],
        quantity: e["quantity"],
      );
    }).toList();
  }

  Future<List<ConditionModel>> fetchConditions() async {
    final data = await _client.get('/stockin/get-conditions');
    return (data['data'] as List).map((e) => ConditionModel.fromJson(e)).toList();
  }

  Future<List<LocationModel>> fetchLocations() async {
    final data = await _client.get('/stockin/get-locations');
    return (data['data'] as List).map((e) => LocationModel.fromJson(e)).toList();
  }
}
