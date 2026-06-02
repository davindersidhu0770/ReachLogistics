class LocationModel {
  final int locationID;
  final String location;

  LocationModel({
    required this.locationID,
    required this.location,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      locationID: json['locationID'],
      location: json['location'],
    );
  }
}