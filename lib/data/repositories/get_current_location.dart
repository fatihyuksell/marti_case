import 'package:marti_case/data/models/location_model.dart';
import 'package:marti_case/data/repositories/location_repository.dart';

class GetCurrentLocation {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  Future<LocationModel> call() async {
    return await repository.getCurrentLocation();
  }
}
