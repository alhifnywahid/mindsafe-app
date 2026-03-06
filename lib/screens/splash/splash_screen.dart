import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/vpn_service.dart';
import 'package:mindsafe_flutter/data/services/domain_classifier.dart';
import 'package:mindsafe_flutter/data/services/version_service.dart';
import 'package:mindsafe_flutter/data/services/sync_service.dart';
import 'package:mindsafe_flutter/data/services/data_manager.dart';
import 'package:mindsafe_flutter/data/services/notification_service.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _pulseAnimation;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  Future<void> _initializeAndNavigate() async {
    // ── Initialize all services ──
    _updateStatus('splash_loading_database'.tr);
    try {
      final db = LocalDatabase();
      await db.init();
      Get.put<LocalDatabase>(db, permanent: true);
      debugPrint('✅ LocalDatabase initialized');
    } catch (e) {
      debugPrint('❌ LocalDatabase init error: $e');
    }

    _updateStatus('splash_loading_auth'.tr);
    try {
      final auth = AuthService();
      await auth.init();
      Get.put<AuthService>(auth, permanent: true);
      debugPrint('✅ AuthService initialized');
    } catch (e) {
      debugPrint('❌ AuthService init error: $e');
    }

    _updateStatus('splash_loading_vpn'.tr);
    try {
      final vpn = VpnService();
      await vpn.init();
      Get.put<VpnService>(vpn, permanent: true);
      debugPrint('✅ VpnService initialized');
    } catch (e) {
      debugPrint('❌ VpnService init error: $e');
    }

    _updateStatus('splash_loading_classifier'.tr);
    final classifier = DomainClassifier();
    await classifier.init();
    Get.put(classifier, permanent: true);
    debugPrint(
      '✅ DomainClassifier loaded: ${classifier.totalDomains.value} domains',
    );

    _updateStatus('splash_loading_services'.tr);
    final versionService = VersionService();
    await versionService.init();
    Get.put(versionService, permanent: true);
    debugPrint(
      '✅ VersionService initialized (v${versionService.currentVersion.value})',
    );

    // Firestore repository
    Get.put(FirestoreRepository(), permanent: true);

    // Data manager
    Get.put(DataManager(), permanent: true);

    // Sync service
    try {
      final sync = SyncService();
      await sync.init();
      Get.put<SyncService>(sync, permanent: true);
      debugPrint('✅ SyncService initialized');
    } catch (e) {
      debugPrint('❌ SyncService init error: $e');
    }

    // Notification service
    try {
      final notif = NotificationService();
      await notif.init();
      Get.put<NotificationService>(notif, permanent: true);
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService init error: $e');
    }

    // Enforce data retention
    _updateStatus('splash_loading_cleanup'.tr);
    try {
      final dataManager = Get.find<DataManager>();
      final deleted = await dataManager.enforceRetention();
      if (deleted > 0) {
        debugPrint('🗑️ Auto-deleted $deleted old records');
      }
    } catch (e) {
      debugPrint('❌ Data retention error: $e');
    }

    debugPrint('✅ All services initialized');

    // ── Auth check & navigation ──
    _updateStatus('splash_loading_ready'.tr);
    await Future.delayed(const Duration(milliseconds: 500));

    final authService = Get.find<AuthService>();

    if (authService.currentUser == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // User is logged in - check if registered in Firestore
    final repo = Get.find<FirestoreRepository>();
    final userId = authService.currentUser!.uid;
    final isRegistered = await repo.checkUserRegistered(userId);

    if (!isRegistered) {
      Get.offAllNamed(AppRoutes.registration);
      return;
    }

    // Registered - check onboarding
    final prefs = Get.find<SharedPreferences>();
    final hasOnboarded = prefs.getBool('onboarding_complete') ?? false;

    if (hasOnboarded) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
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
              // ── Background gradient orbs (same as login) ──
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
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Shield logo with glow (same as login) ──
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
                        'splash_tagline'.tr,
                        style: theme.typography.base.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ── Loading indicator ──
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Status text ──
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
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
