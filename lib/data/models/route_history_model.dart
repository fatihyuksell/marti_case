import 'package:marti_case/data/models/location_model.dart';

class RouteHistoryModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<LocationModel> locationPoints;
  final double totalDistance;

  RouteHistoryModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.locationPoints,
    required this.totalDistance,
  });

  factory RouteHistoryModel.fromJson(Map<String, dynamic> json) {
    return RouteHistoryModel(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      locationPoints: (json['locationPoints'] as List)
          .map((e) => LocationModel.fromJson(e))
          .toList(),
      totalDistance: json['totalDistance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'locationPoints': locationPoints.map((e) => e.toJson()).toList(),
      'totalDistance': totalDistance,
    };
  }
}
