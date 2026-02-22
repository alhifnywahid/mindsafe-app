import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A card matching the Home screen style:
/// border, radius 14, padding 14, subtle shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final Widget? title;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.title, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: title != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                  child: title!,
                ),
                const SizedBox(height: 10),
                child,
              ],
            )
          : child,
    );
  }
}
