/// Interface abstrata de storage local.
///
/// Cubits e serviços devem depender desta interface,
/// nunca de SharedPreferences diretamente.
abstract class StorageService {
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, {required bool value});

  Future<void> remove(String key);
}
