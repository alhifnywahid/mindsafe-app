import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const _key = 'theme_mode';

  final _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;

  /// Human-readable label
  String get themeModeLabel {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'settings_theme_light'.tr;
      case ThemeMode.dark:
        return 'settings_theme_dark'.tr;
      case ThemeMode.system:
        return 'settings_theme_system'.tr;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final prefs = Get.find<SharedPreferences>();
    final stored = prefs.getString(_key) ?? 'system';
    _themeMode.value = _fromString(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    final prefs = Get.find<SharedPreferences>();
    await prefs.setString(_key, _toString(mode));
  }

  void cycleTheme() {
    switch (_themeMode.value) {
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
    }
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  IconData get themeIcon {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
