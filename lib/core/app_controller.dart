import 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;

  ThemeMode get themeMode => _themeMode;

  bool get isEnglish => _locale.languageCode == 'en';

  bool get isSwahili => _locale.languageCode == 'sw';

  bool get isLightMode => _themeMode == ThemeMode.light;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setLanguage(Locale locale) {
    if (locale.languageCode == _locale.languageCode) {
      return;
    }

    if (locale.languageCode != 'en' &&
        locale.languageCode != 'sw') {
      return;
    }

    _locale = locale;
    notifyListeners();
  }

  void toggleLanguage() {
    if (isEnglish) {
      setLanguage(const Locale('sw'));
    } else {
      setLanguage(const Locale('en'));
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (isLightMode) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}