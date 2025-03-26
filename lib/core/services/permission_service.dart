import 'package:geolocator/geolocator.dart';

abstract class PermissionService {
  Future<bool> requestLocationPermission();
  Future<bool> checkLocationPermission();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
