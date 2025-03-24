import 'dart:convert';
import 'package:marti_case/core/services/permission_service.dart';
import 'package:marti_case/core/services/storage_service.dart';
import 'package:marti_case/features/location/data/services/location_service.dart';
import 'package:marti_case/features/location/domain/models/location_model.dart';
import 'package:marti_case/features/location/domain/repositories/location_repository.dart';

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

    // Limit history size if needed
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
}
