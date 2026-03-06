import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the shield glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade + slide animation for content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final authService = Get.find<AuthService>();
      final result = await authService.signInWithGoogle();

      if (result != null) {
        final repo = Get.find<FirestoreRepository>();
        final userId = result.user?.uid;

        if (userId == null) {
          setState(() => _isLoading = false);
          return;
        }

        final isRegistered = await repo.checkUserRegistered(userId);

        if (!isRegistered) {
          Get.offAllNamed(AppRoutes.registration);
        } else {
          final prefs = Get.find<SharedPreferences>();
          final hasOnboarded = prefs.getBool('onboarding_complete') ?? false;
          if (hasOnboarded) {
            Get.offAllNamed(AppRoutes.home);
          } else {
            Get.offAllNamed(AppRoutes.onboarding);
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (context.mounted) {
          showFToast(
            context: context,
            style: const FToastStyleDelta.delta(
              constraints: BoxConstraints(minWidth: double.infinity, maxWidth: double.infinity),
            ),
            alignment: FToastAlignment.topCenter,
            icon: const Icon(Icons.error_outline, color: Colors.red),
            title: Text('dialog_error'.tr),
            description: const Text('Failed to sign in with Google'),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        showFToast(
          context: context,
          style: const FToastStyleDelta.delta(
            constraints: BoxConstraints(minWidth: double.infinity, maxWidth: double.infinity),
          ),
          alignment: FToastAlignment.topCenter,
          icon: const Icon(Icons.error_outline, color: Colors.red),
          title: Text('dialog_error'.tr),
          description: const Text('Failed to sign in with Google'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final primaryColor = theme.colors.primary;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SizedBox.expand(
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Background gradient orbs ──
              Positioned(
                top: -screenSize.height * 0.15,
                left: -screenSize.width * 0.3,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: screenSize.width * 0.8,
                    height: screenSize.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(
                            alpha: 0.15 * _pulseAnimation.value,
                          ),
                          primaryColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -screenSize.height * 0.1,
                right: -screenSize.width * 0.25,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: screenSize.width * 0.7,
                    height: screenSize.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(
                            alpha: 0.1 * _pulseAnimation.value,
                          ),
                          primaryColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // ── Shield logo with glow ──
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) => Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(
                                      alpha: 0.3 * _pulseAnimation.value,
                                    ),
                                    blurRadius: 40 * _pulseAnimation.value,
                                    spreadRadius: 5 * _pulseAnimation.value,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryColor.withValues(alpha: 0.15),
                                      primaryColor.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: 64,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── App name ──
                          Text(
                            'Mindsafe',
                            style: theme.typography.xl3.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colors.foreground,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Tagline ──
                          Text(
                            'login_subtitle'.tr,
                            style: theme.typography.base.copyWith(
                              color: theme.colors.mutedForeground,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(flex: 3),

                          // ── Google Sign In button ──
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: FButton(
                              onPress: _isLoading ? null : _handleGoogleSignIn,
                              prefix: _isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colors.primaryForeground,
                                      ),
                                    )
                                  : const Icon(FIcons.logIn),
                              child: Text(
                                _isLoading
                                    ? 'login_loading'.tr
                                    : 'login_google'.tr,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Footer text ──
                          Text(
                            'login_footer'.tr,
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
