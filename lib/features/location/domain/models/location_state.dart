import 'package:marti_case/features/location/domain/models/location_model.dart';

class LocationState {
  final LocationModel? currentLocation;
  final List<LocationModel> locationHistory;
  final bool isTracking;
  final bool isLoading;
  final String? error;

  LocationState({
    this.currentLocation,
    this.locationHistory = const [],
    this.isTracking = false,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    LocationModel? currentLocation,
    List<LocationModel>? locationHistory,
    bool? isTracking,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      locationHistory: locationHistory ?? this.locationHistory,
      isTracking: isTracking ?? this.isTracking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
