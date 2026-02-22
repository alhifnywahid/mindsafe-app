import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int _expandedIndex = -1; // -1 = none expanded

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    final faqItems = [
      ('faq_q1'.tr, 'faq_a1'.tr, Icons.monitor_heart_outlined),
      ('faq_q2'.tr, 'faq_a2'.tr, Icons.lock_outline),
      ('faq_q3'.tr, 'faq_a3'.tr, Icons.vpn_key_outlined),
      ('faq_q4'.tr, 'faq_a4'.tr, Icons.shield_outlined),
      ('faq_q5'.tr, 'faq_a5'.tr, Icons.dns_outlined),
    ];

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'about_faq'.tr,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: faqItems.length,
        separatorBuilder: (_, __) => Divider(
          color: theme.colors.border.withValues(alpha: 0.15),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final (question, answer, icon) = faqItems[index];
          final isExpanded = _expandedIndex == index;

          return InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? -1 : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: theme.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question,
                          style: theme.typography.sm.copyWith(
                            fontWeight: isExpanded
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isExpanded
                                ? theme.colors.primary
                                : theme.colors.foreground,
                            height: 1.3,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: isExpanded
                              ? theme.colors.primary
                              : theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(
                        left: 48,
                        top: 10,
                        right: 4,
                      ),
                      child: Text(
                        answer,
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                          height: 1.6,
                        ),
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Social Media Screen ──────────────────────────────────────

class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  static const _socials = [
    _SocialItem(
      icon: Icons.camera_alt_outlined,
      label: 'Instagram',
      handle: '@mindsafe.app',
      url: 'https://instagram.com/mindsafe.app',
      color: Color(0xFFE1306C),
    ),
    _SocialItem(
      icon: Icons.play_circle_outline,
      label: 'YouTube',
      handle: 'Mindsafe Official',
      url: 'https://youtube.com/@mindsafe',
      color: Color(0xFFFF0000),
    ),
    _SocialItem(
      icon: Icons.facebook_outlined,
      label: 'Facebook',
      handle: 'Mindsafe App',
      url: 'https://facebook.com/mindsafeapp',
      color: Color(0xFF1877F2),
    ),
    _SocialItem(
      icon: Icons.alternate_email,
      label: 'X (Twitter)',
      handle: '@mindsafe_app',
      url: 'https://x.com/mindsafe_app',
      color: Color(0xFF000000),
    ),
    _SocialItem(
      icon: Icons.telegram,
      label: 'Telegram',
      handle: '@mindsafe_channel',
      url: 'https://t.me/mindsafe_channel',
      color: Color(0xFF0088CC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'about_social'.tr,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _socials.length,
        separatorBuilder: (_, __) => Divider(
          color: theme.colors.border.withValues(alpha: 0.15),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final social = _socials[index];
          return InkWell(
            onTap: () => _openUrl(social.url),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: social.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(social.icon, size: 20, color: social.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          social.label,
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          social.handle,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SocialItem {
  final IconData icon;
  final String label;
  final String handle;
  final String url;
  final Color color;

  const _SocialItem({
    required this.icon,
    required this.label,
    required this.handle,
    required this.url,
    required this.color,
  });
}

// ─── Legal Page (Privacy & Terms) ─────────────────────────────

class LegalPage extends StatelessWidget {
  final String title;
  final String content;

  const LegalPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SelectableText(
          content,
          style: theme.typography.sm.copyWith(
            color: theme.colors.foreground,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

// ─── Helper: About Row (reusable in settings) ─────────────────

class AboutRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final VoidCallback onTap;
  final FThemeData theme;

  const AboutRow({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colors.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colors.foreground,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
