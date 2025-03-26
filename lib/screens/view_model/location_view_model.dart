import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marti_case/data/repositories/get_current_location.dart';
import 'package:marti_case/data/repositories/track_location.dart';
import 'package:marti_case/data/models/location_model.dart';
import 'package:marti_case/data/models/location_state.dart';
import 'package:marti_case/data/repositories/location_repository.dart';
import 'package:marti_case/data/models/route_history_model.dart';

class LocationViewModel extends StateNotifier<LocationState> {
  final GetCurrentLocation _getCurrentLocation;
  final TrackLocation _trackLocation;
  final LocationRepository _locationRepository;
  StreamSubscription<LocationModel>? _locationSubscription;

  LocationViewModel({
    required GetCurrentLocation getCurrentLocation,
    required TrackLocation trackLocation,
    required LocationRepository locationRepository,
  })  : _getCurrentLocation = getCurrentLocation,
        _trackLocation = trackLocation,
        _locationRepository = locationRepository,
        super(LocationState());

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final hasPermission = await _locationRepository.hasLocationPermission();
      if (!hasPermission) {
        final permissionGranted =
            await _locationRepository.requestLocationPermission();
        if (!permissionGranted) {
          state = state.copyWith(
            isLoading: false,
            error: 'Konum izni verilmedi',
          );
          return;
        }
      }

      final location = await _getCurrentLocation();
      final updatedHistory = [...state.locationHistory, location];

      state = state.copyWith(
        currentLocation: location,
        locationHistory: updatedHistory,
        isLoading: false,
      );

      await _locationRepository.saveLocationHistory(location);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchCurrentLocation() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final location = await _getCurrentLocation();

      state = state.copyWith(
        currentLocation: location,
        isLoading: false,
        locationHistory: [...state.locationHistory, location],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startTracking() {
    if (state.isTracking) return;

    state = state.copyWith(isTracking: true, error: null);
    _locationSubscription = _trackLocation().listen(
      (location) {
        state = state.copyWith(
          currentLocation: location,
          locationHistory: [...state.locationHistory, location],
        );
      },
      onError: (error) {
        state = state.copyWith(
          error: error.toString(),
          isTracking: false,
        );
        _locationSubscription?.cancel();
      },
    );
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    Future.microtask(() {
      state = state.copyWith(isTracking: false);
    });
  }

  void clearLocationHistory() {
    state = state.copyWith(locationHistory: []);
  }

  Future<void> resetRoute() async {
    try {
      final currentLocation = state.currentLocation;
      final isTracking = state.isTracking;

      if (state.locationHistory.isNotEmpty) {
        await _locationRepository.saveRouteHistory(state.locationHistory);
      }

      state = state.copyWith(
        locationHistory: [],
        currentLocation: currentLocation,
        isTracking: isTracking,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Rota sıfırlanırken hata: ${e.toString()}',
      );
    }
  }

  Future<List<RouteHistoryModel>> getRouteHistory() async {
    try {
      return await _locationRepository.getRouteHistory();
    } catch (e) {
      state = state.copyWith(
          error: 'Geçmiş rotalar alınırken hata: ${e.toString()}');
      return [];
    }
  }

  void addLocationToHistory(LocationModel location) {
    if (!state.isTracking) return;

    final updatedHistory = List<LocationModel>.from(state.locationHistory)
      ..add(location);

    state = state.copyWith(
      currentLocation: location,
      locationHistory: updatedHistory,
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
