import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> get preferences async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  Future<bool> setValue<T>(String key, T value) async {
    final prefs = await preferences;

    if (value is String) {
      return prefs.setString(key, value);
    } else if (value is int) {
      return prefs.setInt(key, value);
    } else if (value is bool) {
      return prefs.setBool(key, value);
    } else if (value is double) {
      return prefs.setDouble(key, value);
    } else if (value is List<String>) {
      return prefs.setStringList(key, value);
    }
    throw ArgumentError('Desteklenmeyen veri türü: ${value.runtimeType}');
  }

  Future<T?> getValue<T>(String key) async {
    final prefs = await preferences;
    return prefs.get(key) as T?;
  }

  Future<bool> remove(String key) async {
    final prefs = await preferences;
    return prefs.remove(key);
  }

  Future<bool> clear() async {
    final prefs = await preferences;
    return prefs.clear();
  }
}
