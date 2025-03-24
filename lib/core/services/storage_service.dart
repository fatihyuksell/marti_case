import 'package:marti_case/core/services/shared_preferences_manager.dart';

abstract class StorageService {
  Future<void> saveData(String key, dynamic value);
  Future<dynamic> getData(String key);
  Future<void> removeData(String key);
}

class StorageServiceImpl implements StorageService {
  final SharedPreferencesManager _prefsManager;

  StorageServiceImpl(this._prefsManager);

  @override
  Future<void> saveData(String key, dynamic value) async {
    await _prefsManager.setValue(key, value);
  }

  @override
  Future<dynamic> getData(String key) async {
    return await _prefsManager.getValue(key);
  }

  @override
  Future<void> removeData(String key) async {
    await _prefsManager.remove(key);
  }
}
