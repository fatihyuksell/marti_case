import 'package:marti_case/features/location/domain/models/location_model.dart';
import 'package:marti_case/features/location/domain/repositories/location_repository.dart';

class GetCurrentLocation {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  Future<LocationModel> call() async {
    return await repository.getCurrentLocation();
  }
}
