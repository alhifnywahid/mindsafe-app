import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _pageCount = 5;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Translation keys for each page
    final pages = <Map<String, dynamic>>[
      {
        'icon': Icons.shield,
        'title': 'onboarding_title_1'.tr,
        'desc': 'onboarding_desc_1'.tr,
      },
      {
        'icon': Icons.dns,
        'title': 'onboarding_title_2'.tr,
        'desc': 'onboarding_desc_2'.tr,
      },
      {
        'icon': Icons.link,
        'title': 'onboarding_title_3'.tr,
        'desc': 'onboarding_desc_3'.tr,
      },
      {
        'icon': Icons.lock_outline,
        'title': 'onboarding_title_4'.tr,
        'desc': 'onboarding_desc_4'.tr,
      },
      {
        'icon': Icons.insights,
        'title': 'onboarding_title_5'.tr,
        'desc': 'onboarding_desc_5'.tr,
      },
    ];

    return FScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: () {
                    final prefs = Get.find<SharedPreferences>();
                    prefs.setBool('onboarding_complete', true);
                    Get.offAllNamed(AppRoutes.home);
                  },
                  child: Text(
                    'onboarding_skip'.tr,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 64,
                            color: theme.colors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page['title'] as String,
                          style: theme.typography.xl2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colors.foreground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page['desc'] as String,
                          style: theme.typography.base.copyWith(
                            color: theme.colors.mutedForeground,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? theme.colors.primary
                          : theme.colors.mutedForeground.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next / Get Started
            Padding(
              padding: AppSpacing.paddingLg,
              child: SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: () {
                    if (_currentPage < _pageCount - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      final prefs = Get.find<SharedPreferences>();
                      prefs.setBool('onboarding_complete', true);
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                  child: Text(
                    _currentPage < _pageCount - 1
                        ? 'onboarding_next'.tr
                        : 'onboarding_get_started'.tr,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
