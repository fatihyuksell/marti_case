class LocationModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.additionalData,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}
