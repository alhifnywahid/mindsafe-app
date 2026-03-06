import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static const _key = 'locale';

  final _locale = const Locale('id', 'ID').obs;
  Locale get locale => _locale.value;

  String get currentLanguageLabel =>
      _locale.value.languageCode == 'id' ? 'Bahasa Indonesia' : 'English';

  String get currentLanguageCode => _locale.value.languageCode;

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final prefs = Get.find<SharedPreferences>();
    final stored = prefs.getString(_key) ?? 'id';
    if (stored == 'id') {
      _locale.value = const Locale('id', 'ID');
    } else {
      _locale.value = const Locale('en', 'US');
    }
    Get.updateLocale(_locale.value);
  }

  Future<void> setLocale(Locale locale) async {
    _locale.value = locale;
    Get.updateLocale(locale);
    final prefs = Get.find<SharedPreferences>();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    if (_locale.value.languageCode == 'en') {
      await setLocale(const Locale('id', 'ID'));
    } else {
      await setLocale(const Locale('en', 'US'));
    }
  }
}
