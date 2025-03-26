import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marti_case/core/router/app_router.dart';
import 'package:marti_case/core/services/permission_service.dart';
import 'package:marti_case/core/services/shared_preferences_manager.dart';
import 'package:marti_case/core/services/storage_service.dart';
import 'package:marti_case/data/repositories/get_current_location.dart';
import 'package:marti_case/data/repositories/location_repository_impl.dart';
import 'package:marti_case/data/repositories/track_location.dart';
import 'package:marti_case/data/services/location_service.dart';
import 'package:marti_case/data/models/location_state.dart';
import 'package:marti_case/data/repositories/location_repository.dart';
import 'package:marti_case/core/services/background_location_service.dart';
import 'package:marti_case/screens/view_model/location_view_model.dart';

// Router Provider
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

// Servisler
final sharedPreferencesManagerProvider =
    Provider<SharedPreferencesManager>((ref) {
  return SharedPreferencesManager();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefsManager = ref.watch(sharedPreferencesManagerProvider);
  return StorageServiceImpl(prefsManager);
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationServiceImpl();
});

// Repository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    locationService: ref.watch(locationServiceProvider),
    permissionService: ref.watch(permissionServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// UseCases
final getCurrentLocationProvider = Provider<GetCurrentLocation>((ref) {
  return GetCurrentLocation(ref.watch(locationRepositoryProvider));
});

final trackLocationProvider = Provider<TrackLocation>((ref) {
  return TrackLocation(ref.watch(locationRepositoryProvider));
});

// ViewModel
final locationViewModelProvider =
    StateNotifierProvider<LocationViewModel, LocationState>((ref) {
  return LocationViewModel(
    locationRepository: ref.watch(locationRepositoryProvider),
    getCurrentLocation: ref.watch(getCurrentLocationProvider),
    trackLocation: ref.watch(trackLocationProvider),
  );
});

final locationRepository = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    locationService: ref.watch(locationServiceProvider),
    permissionService: ref.watch(permissionServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final backgroundLocationServiceProvider =
    Provider<BackgroundLocationService>((ref) {
  final locationViewModel = ref.read(locationViewModelProvider.notifier);
  return BackgroundLocationService(locationViewModel);
});
