import 'package:get/get.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';
import 'package:mindsafe_flutter/screens/splash/splash_screen.dart';
import 'package:mindsafe_flutter/screens/auth/login_screen.dart';
import 'package:mindsafe_flutter/screens/auth/registration_screen.dart';
import 'package:mindsafe_flutter/screens/onboarding/onboarding_screen.dart';
import 'package:mindsafe_flutter/screens/navigation/main_navigation.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(
      name: AppRoutes.registration,
      page: () => const RegistrationScreen(),
    ),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.home, page: () => MainNavigation()),
  ];
}
