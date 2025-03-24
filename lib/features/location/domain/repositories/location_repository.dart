import 'package:marti_case/features/location/domain/models/location_model.dart';

abstract class LocationRepository {
  Future<LocationModel> getCurrentLocation();
  Stream<LocationModel> trackLocation();
  Future<bool> hasLocationPermission();
  Future<bool> requestLocationPermission();
  Future<void> saveLocationHistory(LocationModel location);
  Future<List<LocationModel>> getLocationHistory();
}
