/// One row of a /stock/lookup response — unit count of the searched
/// product at a single location.
class StockLookupResultModel {
  final String location;
  final int totalCount;

  StockLookupResultModel({required this.location, required this.totalCount});

  factory StockLookupResultModel.fromJson(Map<String, dynamic> json) {
    return StockLookupResultModel(
      location: (json['location'] ?? '').toString(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}