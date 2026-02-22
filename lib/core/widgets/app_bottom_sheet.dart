import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A reusable bottom sheet container that matches the nav bar style:
/// rounded top corners, gradient background, backdrop blur, top border.
///
/// Usage:
/// ```dart
/// showFSheet(
///   context: context,
///   side: FLayout.btt,
///   mainAxisMaxRatio: null,
///   builder: (ctx) => AppBottomSheet(
///     children: [ ... ],
///   ),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheet({super.key, required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const topRadius = Radius.circular(24);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding:
              padding ?? EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
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
                      const Color(0xFF2A2A2E).withValues(alpha: 0.90),
                      const Color(0xFF1C1C1F).withValues(alpha: 0.96),
                    ]
                  : [
                      const Color(0xFFF8F8FA).withValues(alpha: 0.94),
                      const Color(0xFFF0F0F3).withValues(alpha: 0.98),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colors.mutedForeground.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
