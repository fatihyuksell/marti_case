import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marti_case/core/services/permission_service.dart';
import 'package:marti_case/core/services/storage_service.dart';
import 'package:marti_case/features/location/data/services/location_service.dart';
import 'package:marti_case/features/location/domain/models/location_model.dart';
import 'package:marti_case/features/location/domain/models/route_history_model.dart';
import 'package:marti_case/features/location/domain/repositories/location_repository.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationService locationService;
  final PermissionService permissionService;
  final StorageService storageService;

  LocationRepositoryImpl({
    required this.locationService,
    required this.permissionService,
    required this.storageService,
  });

  @override
  Future<LocationModel> getCurrentLocation() async {
    return await locationService.getCurrentLocation();
  }

  @override
  Stream<LocationModel> trackLocation() {
    return locationService.getLocationStream();
  }

  @override
  Future<bool> hasLocationPermission() async {
    return await permissionService.checkLocationPermission();
  }

  @override
  Future<bool> requestLocationPermission() async {
    return await permissionService.requestLocationPermission();
  }

  @override
  Future<void> saveLocationHistory(LocationModel location) async {
    List<LocationModel> history = await getLocationHistory();
    history.add(location);

    if (history.length > 100) {
      history = history.sublist(history.length - 100);
    }

    List<String> serializedHistory =
        history.map((location) => jsonEncode(location.toJson())).toList();

    await storageService.saveData('location_history', serializedHistory);
  }

  @override
  Future<List<LocationModel>> getLocationHistory() async {
    List<String>? serializedHistory =
        await storageService.getData('location_history') as List<String>?;

    if (serializedHistory == null) {
      return [];
    }

    return serializedHistory
        .map((item) => LocationModel.fromJson(jsonDecode(item)))
        .toList();
  }

  static const String _routeHistoryKey = 'route_history';

  @override
  Future<void> saveRouteHistory(List<LocationModel> locationHistory) async {
    if (locationHistory.isEmpty) return;

    try {
      final List<RouteHistoryModel> existingRoutes = await getRouteHistory();

      final RouteHistoryModel newRoute =
          _createRouteFromLocationHistory(locationHistory);

      existingRoutes.add(newRoute);

      final String routesJson =
          jsonEncode(existingRoutes.map((e) => e.toJson()).toList());

      await storageService.saveData(_routeHistoryKey, routesJson);
    } catch (e) {
      debugPrint('Rota geçmişi kaydedilirken hata: $e');
      rethrow;
    }
  }

  @override
  Future<List<RouteHistoryModel>> getRouteHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? routesJson = prefs.getString(_routeHistoryKey);

      if (routesJson == null || routesJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedRoutes = jsonDecode(routesJson);
      return decodedRoutes
          .map((route) => RouteHistoryModel.fromJson(route))
          .toList();
    } catch (e) {
      debugPrint('Rota geçmişi alınırken hata: $e');
      return [];
    }
  }

  // RouteHistoryModel _createRouteFromLocationHistory(
  //     List<LocationModel> locationHistory) {
  //   final firstLocation = locationHistory.first;
  //   final lastLocation = locationHistory.last;

  //   double totalDistance = _calculateTotalDistance(locationHistory);

  //   return RouteHistoryModel(
  //     id: const Uuid().v4(),
  //     startTime: DateTime.fromMillisecondsSinceEpoch(
  //       firstLocation.timestamp.millisecondsSinceEpoch,
  //     ),
  //     endTime: DateTime.fromMillisecondsSinceEpoch(
  //       lastLocation.timestamp.millisecondsSinceEpoch,
  //     ),
  //     locationPoints: locationHistory,
  //     totalDistance: totalDistance,
  //   );
  // }

  // ... existing code ...

  RouteHistoryModel _createRouteFromLocationHistory(
      List<LocationModel> locationHistory) {
    if (locationHistory.isEmpty) {
      print("UYARI: Boş konum geçmişi ile rota oluşturuluyor");
      return RouteHistoryModel(
        id: const Uuid().v4(),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        locationPoints: [],
        totalDistance: 0,
      );
    }

    final firstLocation = locationHistory.first;
    final lastLocation = locationHistory.last;

    final locationPoints = [...locationHistory];

    double totalDistance = _calculateTotalDistance(locationPoints);

    final route = RouteHistoryModel(
      id: const Uuid().v4(),
      startTime: DateTime.fromMillisecondsSinceEpoch(
        firstLocation.timestamp.millisecondsSinceEpoch,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        lastLocation.timestamp.millisecondsSinceEpoch,
      ),
      locationPoints: locationPoints,
      totalDistance: totalDistance,
    );

    print(
        "Rota oluşturuldu: ID=${route.id}, Konum noktaları=${route.locationPoints.length}");

    return route;
  }

// ... existing code ...

  double _calculateDistanceBetweenPoints(
    LocationModel start,
    LocationModel end,
  ) {
    const double earthRadius = 6371000; // metre cinsinden
    final double lat1 = start.latitude * pi / 180;
    final double lon1 = start.longitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double lon2 = end.longitude * pi / 180;

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 *
        atan2(
          sqrt(a),
          sqrt(1 - a),
        );
    return earthRadius * c;
  }

  double _calculateTotalDistance(List<LocationModel> locations) {
    if (locations.length <= 1) return 0;

    double totalDistance = 0;
    for (int i = 0; i < locations.length - 1; i++) {
      totalDistance += _calculateDistanceBetweenPoints(
        locations[i],
        locations[i + 1],
      );
    }

    return totalDistance;
  }
}
