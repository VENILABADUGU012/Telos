import 'package:flutter/material.dart';
import '../storage/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    final saved = StorageService.getThemeMode();
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    final modeStr = mode == ThemeMode.light ? 'light' : mode == ThemeMode.system ? 'system' : 'dark';
    StorageService.saveThemeMode(modeStr);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
