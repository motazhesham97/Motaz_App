import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAuthStorage implements KeyValueStorage {
  SharedPreferencesAuthStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> get(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
      return;
    }

    await _prefs.setString(key, value);
  }
}
