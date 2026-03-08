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

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  static const _totalSteps = 5;
  int _currentStep = 0;

  // Form data
  final _nicknameCtrl = TextEditingController();
  String _ageCategory = '';
  String _gender = '';
  int _dataRetention = 30;
  bool _monitoringConsent = false;

  bool _isSubmitting = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _pulseController.dispose();
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
      if (mounted) {
        showFToast(
          context: context,
          style: const FToastStyleDelta.delta(
            constraints: BoxConstraints(
              minWidth: double.infinity,
              maxWidth: double.infinity,
            ),
          ),
          alignment: FToastAlignment.topCenter,
          icon: const Icon(Icons.error_outline, color: Colors.red),
          title: Text('dialog_error'.tr),
          description: Text('reg_error_save'.tr),
        );
      }
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
                child: Column(
                  children: [
                    // ─── Progress bar (no back button here) ───
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_currentStep + 1} / $_totalSteps',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: (_currentStep + 1) / _totalSteps,
                              ),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: theme
                                        .colors
                                        .mutedForeground
                                        .withValues(alpha: 0.15),
                                    color: primaryColor,
                                    minHeight: 4,
                                  ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: _buildStep(theme),
                          ),
                        ),
                      ),
                    ),

                    // ─── Bottom buttons ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          // Back button (only visible on step 2+)
                          if (_currentStep > 0) ...[
                            Expanded(
                              child: FButton.raw(
                                onPress: _back,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colors.border,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'reg_back'.tr,
                                      style: theme.typography.sm.copyWith(
                                        color: theme.colors.foreground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],

                          // Next / Complete button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                boxShadow: _canProceed
                                    ? [
                                        BoxShadow(
                                          color: primaryColor.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ],
          ),
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

  // ─── Step icon with glow ─────────────────────────────────
  Widget _stepIcon(IconData icon, FThemeData theme) {
    final primaryColor = theme.colors.primary;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(
                alpha: 0.2 * _pulseAnimation.value,
              ),
              blurRadius: 30 * _pulseAnimation.value,
              spreadRadius: 3 * _pulseAnimation.value,
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
          child: Icon(icon, size: 44, color: primaryColor),
        ),
      ),
    );
  }

  // ─── Step 1: Nickname ─────────────────────────────────────

  Widget _buildNicknameStep(FThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xl),
        _stepIcon(Icons.person_outline_rounded, theme),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_nickname_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colors.foreground,
            letterSpacing: -0.3,
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
            filled: true,
            fillColor: theme.colors.primary.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: theme.colors.border.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
        const SizedBox(height: AppSpacing.xl),
        _stepIcon(Icons.cake_outlined, theme),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_age_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colors.foreground,
            letterSpacing: -0.3,
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
        const SizedBox(height: AppSpacing.xl),
        _stepIcon(Icons.wc_rounded, theme),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_gender_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colors.foreground,
            letterSpacing: -0.3,
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
        const SizedBox(height: AppSpacing.xl),
        _stepIcon(Icons.auto_delete_outlined, theme),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_retention_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colors.foreground,
            letterSpacing: -0.3,
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
        const SizedBox(height: AppSpacing.xl),
        _stepIcon(Icons.verified_user_outlined, theme),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'reg_consent_title'.tr,
          style: theme.typography.xl2.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colors.foreground,
            letterSpacing: -0.3,
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _monitoringConsent
                    ? theme.colors.primary
                    : theme.colors.border,
                width: _monitoringConsent ? 2 : 1,
              ),
              color: _monitoringConsent
                  ? theme.colors.primary.withValues(alpha: 0.08)
                  : theme.colors.primary.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colors.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: theme.colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'reg_consent_agree'.tr,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _monitoringConsent,
                  onChanged: (v) => setState(() => _monitoringConsent = v),
                  activeThumbColor: theme.colors.primary,
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
    final primaryColor = theme.colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? primaryColor : theme.colors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? primaryColor.withValues(alpha: 0.08)
                : primaryColor.withValues(alpha: 0.02),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : theme.colors.border,
                    width: isSelected ? 6 : 2,
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
