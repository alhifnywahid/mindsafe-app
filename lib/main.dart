import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';
import 'package:mindsafe_flutter/routes/app_pages.dart';
import 'package:mindsafe_flutter/app/controllers/theme_controller.dart';
import 'package:mindsafe_flutter/app/controllers/language_controller.dart';
import 'package:mindsafe_flutter/core/localization/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only Firebase + SharedPreferences before runApp (fast, needed for theming)
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);

  // Theme + Language controllers (need SharedPreferences, fast)
  Get.put(ThemeController(), permanent: true);
  Get.put(LanguageController(), permanent: true);

  await initializeDateFormatting();

  debugPrint('✅ Minimal init done — launching UI');
  runApp(const MindsafeApp());
}

class MindsafeApp extends StatelessWidget {
  const MindsafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // ─── Premium ForUI Themes (tinted, not plain gray) ───
    // Dark: deep indigo-navy tones
    final foruiDark = FThemeData(
      colors: FThemes.zinc.dark.colors.copyWith(
        background: const Color(0xFF0C0B1A), // deep indigo-navy
        foreground: const Color(0xFFEDE9FE), // soft lavender white
        primary: const Color(0xFF818CF8), // bright indigo
        primaryForeground: const Color(0xFFF5F3FF), // almost white
        secondary: const Color(0xFF1E1B3A), // muted indigo surface
        secondaryForeground: const Color(0xFFC4B5FD), // light purple
        muted: const Color(0xFF1A1732), // dark indigo muted
        mutedForeground: const Color(0xFF8B8AA0), // soft gray-purple
        card: const Color(0xFF14122A), // dark card
        border: const Color(0xFF2A2648), // subtle purple border
      ),
      typography: FThemes.zinc.dark.typography,
      style: FThemes.zinc.dark.style,
    );

    // Light: warm lavender-cream tones
    final foruiLight = FThemeData(
      colors: FThemes.zinc.light.colors.copyWith(
        background: const Color(0xFFF4F2FF), // soft lavender
        foreground: const Color(0xFF1A1535), // deep indigo text
        primary: const Color(0xFF6366F1), // indigo
        primaryForeground: const Color(0xFFFFFBFF), // pure white
        secondary: const Color(0xFFEDE9FE), // light lavender surface
        secondaryForeground: const Color(0xFF3B366B), // indigo text
        muted: const Color(0xFFE8E3F8), // muted lavender
        mutedForeground: const Color(0xFF6E6A8A), // soft purple-gray
        card: const Color(0xFFFCFAFF), // cream-lavender card
        border: const Color(0xFFD8D2EE), // soft purple border
      ),
      typography: FThemes.zinc.light.typography,
      style: FThemes.zinc.light.style,
    );

    // Material dark theme (synced to ForUI colors)
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: foruiDark.colors.primary,
        secondary: foruiDark.colors.secondary,
        surface: foruiDark.colors.background,
        error: foruiDark.colors.error,
      ),
      scaffoldBackgroundColor: foruiDark.colors.background,
    );

    // Material light theme (synced to ForUI colors)
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: foruiLight.colors.primary,
        secondary: foruiLight.colors.secondary,
        surface: foruiLight.colors.background,
        error: foruiLight.colors.error,
      ),
      scaffoldBackgroundColor: foruiLight.colors.background,
    );

    return Obx(() {
      final tm = themeController.themeMode;
      final langCtrl = Get.find<LanguageController>();
      final currentLocale = langCtrl.locale;

      return GetMaterialApp(
        title: 'Mindsafe',
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: currentLocale,
        fallbackLocale: const Locale('en', 'US'),
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: tm,
        builder: (context, child) {
          // Pick ForUI theme based on actual brightness
          final brightness = Theme.of(context).brightness;
          final foruiTheme = brightness == Brightness.dark
              ? foruiDark
              : foruiLight;
          return FTheme(
            data: foruiTheme,
            child: FToaster(child: child!),
          );
        },
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      );
    });
  }
}
