import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marti_case/features/location/domain/models/location_model.dart';

abstract class LocationService {
  Future<LocationModel> getCurrentLocation();
  Stream<LocationModel> getLocationStream();
}

class LocationServiceImpl implements LocationService {
  @override
  Future<LocationModel> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      rethrow;
    }
  }

  @override
  Stream<LocationModel> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).map((position) => LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        ));
  }
}
