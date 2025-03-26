class LocationModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.additionalData,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      additionalData: json['additionalData'],
      accuracy: json['accuracy'],
      altitude: json['altitude'],
      heading: json['heading'],
      speed: json['speed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
      'accuracy': accuracy,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
    };
  }
}
