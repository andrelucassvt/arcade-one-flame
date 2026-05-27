import 'package:arcade_one/common/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementação de [StorageService] usando [SharedPreferences].
class SharedPreferencesStorageService implements StorageService {
  const SharedPreferencesStorageService(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<void> setInt(String key, int value) async =>
      _prefs.setInt(key, value);

  @override
  Future<double?> getDouble(String key) async => _prefs.getDouble(key);

  @override
  Future<void> setDouble(String key, double value) async =>
      _prefs.setDouble(key, value);

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      _prefs.setString(key, value);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);
}
