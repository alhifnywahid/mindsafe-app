import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final theme = FTheme.of(context);

    return FScaffold(
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield,
                  size: 80,
                  color: theme.colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'login_title'.tr,
                style: theme.typography.xl2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Subtitle
              Text(
                'login_subtitle'.tr,
                style: theme.typography.base.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Google Sign-In
              FButton(
                onPress: () async {
                  final result = await authService.signInWithGoogle();
                  if (result != null) {
                    // Check if user is registered in Firestore
                    final repo = Get.find<FirestoreRepository>();
                    final userId = result.user?.uid;

                    if (userId == null) return;

                    final isRegistered = await repo.checkUserRegistered(userId);

                    if (!isRegistered) {
                      // New user → registration form
                      Get.offAllNamed(AppRoutes.registration);
                    } else {
                      // Existing user → check onboarding
                      final prefs = Get.find<SharedPreferences>();
                      final hasOnboarded =
                          prefs.getBool('onboarding_complete') ?? false;
                      if (hasOnboarded) {
                        Get.offAllNamed(AppRoutes.home);
                      } else {
                        Get.offAllNamed(AppRoutes.onboarding);
                      }
                    }
                  } else {
                    Get.snackbar(
                      'dialog_error'.tr,
                      'Failed to sign in with Google',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                prefix: const Icon(FIcons.logIn),
                child: Text('login_google'.tr),
              ),

              const SizedBox(height: AppSpacing.xl),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
