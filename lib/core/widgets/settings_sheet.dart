import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/core/widgets/app_bottom_sheet.dart';

/// A reusable bottom sheet for choosing a setting value.
///
/// Shows a title, optional description, and a list of selectable options
/// styled like the Monitoring Sheet from Home screen.
///
/// Usage:
/// ```dart
/// showSettingsSheet<ThemeMode>(
///   context: context,
///   title: 'Theme',
///   description: 'Choose your preferred theme ...',
///   options: [ SettingsOption(value: ThemeMode.light, ... ) ],
///   selectedValue: ThemeMode.light,
///   onSelected: (mode) => ...,
/// );
/// ```
Future<void> showSettingsSheet<T>({
  required BuildContext context,
  required String title,
  String? description,
  required List<SettingsOption<T>> options,
  T? selectedValue,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SettingsSheetContent<T>(
      title: title,
      description: description,
      options: options,
      selectedValue: selectedValue,
      onSelected: (value) {
        Navigator.pop(context);
        onSelected(value);
      },
    ),
  );
}

/// Model for a selectable option inside the sheet.
class SettingsOption<T> {
  final T value;
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? description;

  const SettingsOption({
    required this.value,
    required this.icon,
    required this.label,
    this.iconColor,
    this.description,
  });
}

/// Internal sheet widget.
class _SettingsSheetContent<T> extends StatelessWidget {
  final String title;
  final String? description;
  final List<SettingsOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  const _SettingsSheetContent({
    required this.title,
    this.description,
    required this.options,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return AppBottomSheet(
      children: [
        // Title
        Text(
          title,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
        ),

        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 20),

        // Options
        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final isSelected = option.value == selectedValue;

          return Column(
            children: [
              if (idx > 0) const SizedBox(height: 10),
              _OptionTile<T>(
                option: option,
                isSelected: isSelected,
                theme: theme,
                onTap: () => onSelected(option.value),
              ),
            ],
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }
}

/// A single selectable option tile, styled like _MonitoringToggle.
class _OptionTile<T> extends StatelessWidget {
  final SettingsOption<T> option;
  final bool isSelected;
  final FThemeData theme;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.4)
                  : theme.colors.border,
            ),
            color: isSelected ? accentColor.withValues(alpha: 0.06) : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (option.iconColor ?? accentColor).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option.icon,
                  size: 20,
                  color:
                      option.iconColor ??
                      (isSelected ? accentColor : theme.colors.mutedForeground),
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    if (option.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.description!,
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Check icon
              if (isSelected)
                Icon(Icons.check_circle, color: accentColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// A confirmation bottom sheet for dangerous actions.
///
/// Shows title, description, and confirm/cancel buttons.
Future<bool?> showConfirmSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmLabel,
  Color? confirmColor,
  IconData? icon,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConfirmSheetContent(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
      icon: icon,
    ),
  );
}

class _ConfirmSheetContent extends StatelessWidget {
  final String title;
  final String description;
  final String confirmLabel;
  final Color? confirmColor;
  final IconData? icon;

  const _ConfirmSheetContent({
    required this.title,
    required this.description,
    required this.confirmLabel,
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dangerColor = confirmColor ?? theme.colors.error;

    return AppBottomSheet(
      children: [
        // Icon
        if (icon != null) ...[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: dangerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: dangerColor),
          ),
          const SizedBox(height: 16),
        ],

        // Title
        Text(
          title,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          description,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Buttons row
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => Navigator.pop(context, false),
                child: Text('dialog_cancel'.tr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FButton(
                variant: FButtonVariant.destructive,
                onPress: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
