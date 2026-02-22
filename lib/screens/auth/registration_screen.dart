import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:mindsafe_flutter/data/services/auth_service.dart';
import 'package:mindsafe_flutter/data/services/local_database.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/core/constants/app_spacing.dart';
import 'package:mindsafe_flutter/routes/app_routes.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _totalSteps = 5;
  int _currentStep = 0;

  // Form data
  final _nicknameCtrl = TextEditingController();
  String _ageCategory = '';
  String _gender = '';
  int _dataRetention = 30;
  bool _monitoringConsent = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nicknameCtrl.text.trim().length >= 2;
      case 1:
        return _ageCategory.isNotEmpty;
      case 2:
        return _gender.isNotEmpty;
      case 3:
        return true; // always has default
      case 4:
        return _monitoringConsent;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final auth = Get.find<AuthService>();
      final repo = Get.find<FirestoreRepository>();
      final db = Get.find<LocalDatabase>();
      final userId = auth.currentUser?.uid;

      if (userId == null) return;

      // Save to Firestore
      await repo.saveRegistrationData(
        userId: userId,
        nickname: _nicknameCtrl.text.trim(),
        ageCategory: _ageCategory,
        gender: _gender,
        dataRetentionDays: _dataRetention,
        monitoringConsent: _monitoringConsent,
      );

      // Save data retention to local settings
      final settings = db.settings.get('default');
      if (settings != null) {
        settings.dataRetentionDays = _dataRetention;
        settings.save();
      }

      // Go to onboarding
      Get.offAllNamed(AppRoutes.onboarding);
    } catch (e) {
      Get.snackbar(
        'dialog_error'.tr,
        'reg_error_save'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // ─── Progress bar ───
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.colors.foreground,
                          ),
                          onPressed: _back,
                        )
                      else
                        const SizedBox(width: 48),
                      Text(
                        '${_currentStep + 1} / $_totalSteps',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: theme.colors.mutedForeground.withValues(
                        alpha: 0.2,
                      ),
                      color: theme.colors.primary,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Step content ───
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SingleChildScrollView(
                    key: ValueKey(_currentStep),
                    padding: AppSpacing.paddingLg,
                    child: _buildStep(theme),
                  ),
                ),
              ),
            ),

            // ─── Bottom button ───
            Padding(
              padding: AppSpacing.paddingLg,
              child: SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: _canProceed
                      ? () {
                          if (_isSubmitting) return;
                          _next();
                        }
                      : null,
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colors.background,
                          ),
                        )
                      : Text(
                          _currentStep < _totalSteps - 1
                              ? 'reg_next'.tr
                              : 'reg_complete'.tr,
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

  Widget _buildStep(FThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildNicknameStep(theme);
      case 1:
        return _buildAgeStep(theme);
      case 2:
        return _buildGenderStep(theme);
      case 3:
        return _buildRetentionStep(theme);
      case 4:
        return _buildConsentStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Nickname ─────────────────────────────────────

  Widget _buildNicknameStep(FThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_outline, size: 64, color: theme.colors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_nickname_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'reg_nickname_desc'.tr,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _nicknameCtrl,
          textAlign: TextAlign.center,
          style: theme.typography.lg.copyWith(color: theme.colors.foreground),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'reg_nickname_hint'.tr,
            hintStyle: TextStyle(color: theme.colors.mutedForeground),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2: Age Category ─────────────────────────────────

  Widget _buildAgeStep(FThemeData theme) {
    final options = [
      {'value': '13-15', 'label': '13 – 15 ${'reg_years'.tr}'},
      {'value': '16-18', 'label': '16 – 18 ${'reg_years'.tr}'},
      {'value': '19+', 'label': '19+ ${'reg_years'.tr}'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cake_outlined, size: 64, color: theme.colors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_age_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'reg_age_desc'.tr,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ...options.map(
          (opt) => _radioTile(
            value: opt['value']!,
            label: opt['label']!,
            groupValue: _ageCategory,
            onChanged: (v) => setState(() => _ageCategory = v),
            theme: theme,
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Gender ───────────────────────────────────────

  Widget _buildGenderStep(FThemeData theme) {
    final options = [
      {'value': 'male', 'label': 'reg_male'.tr, 'icon': Icons.male},
      {'value': 'female', 'label': 'reg_female'.tr, 'icon': Icons.female},
      {
        'value': 'unspecified',
        'label': 'reg_unspecified'.tr,
        'icon': Icons.do_not_disturb_alt_outlined,
      },
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wc, size: 64, color: theme.colors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_gender_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ...options.map(
          (opt) => _radioTile(
            value: opt['value'] as String,
            label: opt['label'] as String,
            groupValue: _gender,
            onChanged: (v) => setState(() => _gender = v),
            theme: theme,
            leading: Icon(
              opt['icon'] as IconData,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 4: Data Retention ───────────────────────────────

  Widget _buildRetentionStep(FThemeData theme) {
    final options = [
      {'value': 7, 'label': '7 ${'reg_days'.tr}'},
      {'value': 30, 'label': '30 ${'reg_days'.tr} (${'reg_default'.tr})'},
      {'value': 90, 'label': '90 ${'reg_days'.tr}'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_delete_outlined, size: 64, color: theme.colors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_retention_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'reg_retention_desc'.tr,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ...options.map(
          (opt) => _radioTile(
            value: opt['value'].toString(),
            label: opt['label'] as String,
            groupValue: _dataRetention.toString(),
            onChanged: (v) => setState(() => _dataRetention = int.parse(v)),
            theme: theme,
          ),
        ),
      ],
    );
  }

  // ─── Step 5: Monitoring Consent ───────────────────────────

  Widget _buildConsentStep(FThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 64,
          color: theme.colors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_consent_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'reg_consent_desc'.tr,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        InkWell(
          onTap: () => setState(() => _monitoringConsent = !_monitoringConsent),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _monitoringConsent
                    ? theme.colors.primary
                    : theme.colors.border,
                width: _monitoringConsent ? 2 : 1,
              ),
              color: _monitoringConsent
                  ? theme.colors.primary.withValues(alpha: 0.05)
                  : null,
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _monitoringConsent,
                  onChanged: (v) =>
                      setState(() => _monitoringConsent = v ?? false),
                  activeColor: theme.colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'reg_consent_agree'.tr,
                    style: theme.typography.base.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Radio Tile Helper ────────────────────────────────────

  Widget _radioTile({
    required String value,
    required String label,
    required String groupValue,
    required ValueChanged<String> onChanged,
    required FThemeData theme,
    Widget? leading,
  }) {
    final isSelected = groupValue == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.colors.primary : theme.colors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? theme.colors.primary.withValues(alpha: 0.05)
                : null,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 12)],
              Expanded(
                child: Text(
                  label,
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? theme.colors.primary : theme.colors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
