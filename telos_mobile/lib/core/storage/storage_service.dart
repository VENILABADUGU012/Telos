import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConstants.keyToken, token);
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.keyToken);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(AppConstants.keyToken);
  }

  static Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString(AppConstants.keyTheme, mode);
  }

  static String getThemeMode() {
    return _prefs?.getString(AppConstants.keyTheme) ?? 'dark';
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
