import 'package:marti_case/features/location/domain/models/location_model.dart';
import 'package:marti_case/features/location/domain/repositories/location_repository.dart';

class TrackLocation {
  final LocationRepository repository;

  TrackLocation(this.repository);

  Stream<LocationModel> call() {
    return repository.trackLocation();
  }
}
