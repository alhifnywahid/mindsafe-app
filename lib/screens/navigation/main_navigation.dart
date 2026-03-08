import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/version_service.dart';
import 'package:mindsafe_flutter/screens/home/home_screen.dart';
import 'package:mindsafe_flutter/screens/history/history_screen.dart';
import 'package:mindsafe_flutter/screens/insights/insights_screen.dart';
import 'package:mindsafe_flutter/screens/settings/settings_screen.dart';
import 'package:mindsafe_flutter/screens/admin/admin_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _versionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (_versionChecked) return;
    _versionChecked = true;

    try {
      final versionService = Get.find<VersionService>();
      await versionService.checkForUpdate();

      if (versionService.updateAvailable.value && mounted) {
        versionService.showUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Version check skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final isAdmin = authService.isAdmin;
    final theme = FTheme.of(context);

    // Admin: dashboard, rules, notification, settings
    // User: home, insights, history, settings
    final screens = isAdmin
        ? <Widget>[
            const AdminDashboardScreen(),
            const AdminRulesScreen(),
            const AdminNotificationScreen(),
            const SettingsScreen(),
          ]
        : <Widget>[
            const HomeScreen(),
            const InsightsScreen(),
            const HistoryScreen(),
            const SettingsScreen(),
          ];

    final navItems = isAdmin
        ? <_NavItemData>[
            _NavItemData(
              Icons.dashboard_outlined,
              Icons.dashboard,
              'admin_dashboard'.tr,
            ),
            _NavItemData(Icons.rule_outlined, Icons.rule, 'admin_rules'.tr),
            _NavItemData(
              Icons.notifications_outlined,
              Icons.notifications_active,
              'admin_notif'.tr,
            ),
            _NavItemData(
              Icons.settings_outlined,
              Icons.settings_rounded,
              'nav_settings'.tr,
            ),
          ]
        : <_NavItemData>[
            _NavItemData(
              Icons.home_outlined,
              Icons.home_rounded,
              'nav_home'.tr,
            ),
            _NavItemData(
              Icons.lightbulb_outline,
              Icons.lightbulb_rounded,
              'nav_insights'.tr,
            ),
            _NavItemData(
              Icons.history_outlined,
              Icons.history_rounded,
              'nav_history'.tr,
            ),
            _NavItemData(
              Icons.settings_outlined,
              Icons.settings_rounded,
              'nav_settings'.tr,
            ),
          ];

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _FloatingNavBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        theme: theme,
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData(this.icon, this.activeIcon, this.label);
}

// ─── Bottom Nav Bar (Bybit Style) ─────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final List<_NavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final FThemeData theme;

  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const topRadius = Radius.circular(28);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 68 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: topRadius,
              topRight: topRadius,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF2A2A2E).withValues(alpha: 0.72),
                      const Color(0xFF1C1C1F).withValues(alpha: 0.82),
                    ]
                  : [
                      const Color(0xFFF8F8FA).withValues(alpha: 0.78),
                      const Color(0xFFF0F0F3).withValues(alpha: 0.88),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top highlight strip (soft reflection)
              Positioned(
                top: 0,
                left: 32,
                right: 32,
                child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.0),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                    ),
                  ),
                ),
              ),

              // Nav items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  items.length,
                  (i) => _NavItem(
                    data: items[i],
                    isActive: currentIndex == i,
                    onTap: () => onTap(i),
                    accentColor: theme.colors.primary,
                    isDark: isDark,
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

// ─── Nav Item ─────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isDark;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor;
    final inactiveColor = isDark
        ? const Color(0xFF6B6B70)
        : const Color(0xFF9E9EA3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              child: AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(
                  isActive ? data.activeIcon : data.icon,
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
