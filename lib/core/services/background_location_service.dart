import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:marti_case/data/models/location_model.dart';
import 'package:marti_case/screens/view_model/location_view_model.dart';

class BackgroundLocationService {
  final LocationViewModel locationViewModel;
  bool _isRunning = false;

  BackgroundLocationService(this.locationViewModel);

  void initialize() {
    bg.BackgroundGeolocation.ready(bg.Config(
      //TODO: toggle for debug
      debug: true,
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 100,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      heartbeatInterval: 60,
      pausesLocationUpdatesAutomatically: false,
      locationAuthorizationRequest: 'Always',
      backgroundPermissionRationale: bg.PermissionRationale(
          title: "Arka plan konum izni gerekli",
          message:
              "Uygulamanın arka planda konum takibi yapabilmesi için izin gerekiyor"),
    )).then((bg.State state) {
      debugPrint('[BackgroundLocationService] Hazır: ${state.toMap()}');

      bg.BackgroundGeolocation.onLocation(_onLocation);
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      bg.BackgroundGeolocation.onActivityChange(_onActivityChange);
      bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    });
  }

  void startTracking() {
    if (_isRunning) return;

    debugPrint('[BackgroundLocationService] Konum takibi başlatılıyor...');
    bg.BackgroundGeolocation.start();
    _isRunning = true;
  }

  void stopTracking() {
    if (!_isRunning) return;

    debugPrint('[BackgroundLocationService] Konum takibi durduruluyor...');
    bg.BackgroundGeolocation.stop();
    _isRunning = false;
  }

  void toggleTracking() {
    if (_isRunning) {
      stopTracking();
    } else {
      startTracking();
    }
  }

  void _onLocation(bg.Location location) {
    debugPrint(
        '[BackgroundLocationService] Konum: ${location.coords.latitude}, ${location.coords.longitude}');

    final locationModel = LocationModel(
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
      timestamp: DateTime.parse(location.timestamp),
      accuracy: location.coords.accuracy,
      altitude: location.coords.altitude,
      heading: location.coords.heading,
      speed: location.coords.speed,
    );

    locationViewModel.addLocationToHistory(locationModel);
  }

  void _onMotionChange(bg.Location location) {
    final isMoving = location.isMoving;
    debugPrint('[BackgroundLocationService] Hareket durumu: $isMoving');

    if (isMoving) {
      //FIXME: Accuracy high - can take 10 meter distance or same for all project (mean : 100)?
      bg.BackgroundGeolocation.setConfig(bg.Config(
        distanceFilter: 10.0,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      ));
    } else {
      //FIXME: Accuracy high - can take 50 meter distance or same for all project (mean : 100)?
      bg.BackgroundGeolocation.setConfig(bg.Config(
        distanceFilter: 50.0,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_MEDIUM,
      ));
    }
  }

  void _onActivityChange(bg.ActivityChangeEvent event) {
    debugPrint(
        '[Bg location] Aktivite: ${event.activity} (güven: ${event.confidence}%)');
  }

  void _onProviderChange(bg.ProviderChangeEvent event) {
    debugPrint('[Bg location] Konum sağlayıcı durumu: ${event.enabled}');

    if (!event.enabled) {
      // If location service is disabled, show dialog
      // showDialog(
      //   context: context,
      //   builder: (context) => const AlertDialog(
      //     title: Text('Konum servisleri kapalı'),
      //     content: Text(
      //         'Konum servisleri kapalı olduğu için konum takibi durduruldu.'),
      //   ),
      // );
    }
  }

  void dispose() {
    bg.BackgroundGeolocation.removeListeners();
    stopTracking();
  }
}
