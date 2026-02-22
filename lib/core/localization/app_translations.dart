import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUS, 'id_ID': idID};

  static const Map<String, String> enUS = {
    // ─── Navigation ───
    'nav_home': 'Home',
    'nav_insights': 'Insights',
    'nav_history': 'History',
    'nav_settings': 'Settings',
    'nav_admin': 'Admin',

    // ─── Home Screen ───
    'home_greeting': 'Hi, @name 👋',
    'home_monitoring': 'Monitoring',
    'home_start': 'Start Monitoring',
    'home_stop': 'Stop Monitoring',
    'home_activate': 'Activate',
    'home_deactivate': 'Deactivate',
    'home_vpn_active': 'VPN Active',
    'home_vpn_inactive': 'VPN Inactive',
    'home_accessibility_warning': 'Accessibility Service Not Enabled',
    'home_accessibility_desc':
        'Enable Accessibility Service for full URL monitoring across browsers.',
    'home_enable': 'Enable',
    'home_today_stats': "Today's Activity",
    'home_domains': 'Domains',
    'home_duration': 'Duration',
    'home_urls': 'URLs',
    'home_minutes': 'min',
    'home_admin_badge': 'Admin',
    'home_quick_actions': 'Quick Actions',
    'home_view_history': 'View History',
    'home_view_insights': 'View Insights',
    'home_weekly_summary': 'Weekly Summary',
    'home_weekly_duration': 'Total Duration',
    'home_last_7_days': 'Last 7 Days',
    'home_hours': 'h',
    'home_monitoring_active_for': 'Monitoring active for @hours h today',
    'home_no_activity': 'No activity yet today',
    'home_insight': 'Insight',
    'home_insight_up': 'Activity increased vs yesterday',
    'home_insight_down': 'Activity decreased vs yesterday',
    'home_insight_stable': 'Activity is stable',
    'home_insight_new': 'Start monitoring to see insights',
    'home_from_yesterday': 'from yesterday',
    'home_same_as_yesterday': 'Same as yesterday',
    'home_services': 'Services',
    'home_vpn_service': 'VPN Service',
    'home_url_capture': 'URL Capture',
    'home_active': 'Active',
    'home_inactive': 'Inactive',
    'home_protected': 'Your browsing is being monitored',
    'home_not_protected': 'Tap to start monitoring',
    'home_monitoring_all_active': 'All Monitoring Active',
    'home_monitoring_partial': 'Partial Monitoring',
    'home_monitoring_inactive': 'Monitoring Inactive',
    'home_monitoring_title': 'Monitoring Settings',
    'home_monitoring_subtitle':
        'Configure how your browsing activity is monitored',
    'home_vpn_desc':
        'Captures all domain-level DNS queries system-wide from every app on your device.',
    'home_url_capture_desc':
        'Reads the URL from your browser address bar for detailed page-level tracking.',
    'home_top_domains': 'Top Domains',
    'home_today': 'Today',
    'home_category_breakdown': 'Category Breakdown',
    'home_notification': 'Notification',
    'home_notification_desc':
        'Get alerted when an unsafe website is detected while browsing.',

    // ─── History Screen ───
    'history_title': 'History',
    'history_empty': 'No browsing history yet',
    'history_empty_desc': 'Start monitoring to track your activity',
    'history_daily': 'Daily',
    'history_weekly': 'Weekly',
    'history_monthly': 'Monthly',
    'history_daily_title': "Today's Activity",
    'history_weekly_title': '7-Day Activity',
    'history_monthly_title': '30-Day Activity',
    'history_domains_count': '@count domains',
    'history_categories': 'Categories',
    'history_timeline': 'Timeline',
    'history_today': 'Today',
    'history_this_week': 'This Week',
    'history_this_month': 'This Month',
    'history_yesterday': 'Yesterday',
    'history_total': 'Total',
    'history_average': 'Average',
    'history_highest': 'Highest',
    'history_top_domains': 'Top Domains',
    'history_visits': '@count visits',
    'history_time_spent': 'Time Spent',
    'history_seconds': '@count sec',
    'history_min_sec': '@min min @sec sec',
    'history_hours_min': '@hrs hrs @min min',
    'history_tab_overview': 'Overview',
    'history_tab_calendar': 'Calendar',
    'history_calendar_detail': 'Activity Detail',
    'history_calendar_accessed': 'domains accessed',
    'history_calendar_empty': 'No activity on this date',

    // ─── Insights Screen ───
    'insights_title': 'Insights',
    'insights_empty': 'Insights Coming Soon',
    'insights_empty_desc': 'Start monitoring to generate personalized insights',
    'insights_monitoring_active': 'Monitoring is active',
    'insights_summary': 'Summary',
    'insights_total_domains': 'Total Domains',
    'insights_total_duration': 'Total Duration',
    'insights_avg_daily': 'Daily Average',
    'insights_your_insights': 'Your Insights',
    'insights_high_activity': 'High Activity',
    'insights_high_activity_desc':
        'You visited @count unique domains. Consider reducing browsing.',
    'insights_clean': 'All Clear',
    'insights_clean_desc': 'No risky activity detected today. Keep it up!',
    'insights_adult_detected': 'Adult Content Detected',
    'insights_adult_desc':
        '@count visits to adult content sites were detected.',
    'insights_mixed_detected': 'Mixed Content',
    'insights_mixed_desc':
        '@count visits to mixed content sites. Review your browsing habits.',
    'insights_extended_usage': 'Extended Usage',
    'insights_extended_desc':
        'You spent @mins minutes browsing. Consider taking breaks.',
    'insights_low_activity': 'Low Activity',
    'insights_low_activity_desc':
        'Only @count domains visited. Good digital discipline!',
    'insights_hours': 'hrs',
    'insights_minutes': 'min',
    'insights_badge_today': 'Today',
    'insights_badge_weekly': 'Weekly',
    'insights_badge_monthly': 'Monthly',
    'insights_weekly_trend_up': 'Activity Increasing',
    'insights_weekly_trend_up_desc':
        'Browsing activity is up @pct% compared to last week.',
    'insights_weekly_trend_down': 'Activity Decreasing',
    'insights_weekly_trend_down_desc':
        'Browsing activity is down @pct% compared to last week.',
    'insights_weekly_avg': 'Weekly Average',
    'insights_weekly_avg_desc':
        'You visit an average of @avg domains per day this week.',
    'insights_above_avg': 'Above Average',
    'insights_above_avg_desc':
        'Today you visited @today domains, above your @avg daily average.',
    'insights_below_avg': 'Below Average',
    'insights_below_avg_desc':
        'Today you visited @today domains, below your @avg daily average.',
    'insights_most_active_day': 'Most Active Day',
    'insights_most_active_day_desc':
        '@day is your most active browsing day this week.',
    'insights_day_mon': 'Monday',
    'insights_day_tue': 'Tuesday',
    'insights_day_wed': 'Wednesday',
    'insights_day_thu': 'Thursday',
    'insights_day_fri': 'Friday',
    'insights_day_sat': 'Saturday',
    'insights_day_sun': 'Sunday',
    'insights_monthly_domains': 'Monthly Overview',
    'insights_monthly_domains_desc':
        '@count unique domains visited with @visits total visits this month.',
    'insights_monthly_duration': 'Monthly Screen Time',
    'insights_monthly_duration_desc':
        'You spent approximately @hours hours browsing this month.',

    // ─── Settings Screen ───
    'settings_title': 'Settings',
    'settings_appearance': 'Appearance',
    'settings_theme': 'Theme',
    'settings_theme_light': 'Light',
    'settings_theme_dark': 'Dark',
    'settings_theme_system': 'System',
    'settings_language': 'Language',
    'settings_language_en': 'English',
    'settings_language_id': 'Bahasa Indonesia',
    'settings_monitoring': 'Monitoring',
    'settings_url_monitoring': 'URL Monitoring',
    'settings_url_enabled': 'Enabled',
    'settings_url_disabled': 'Disabled - Tap to enable',
    'settings_dns_monitoring': 'DNS Monitoring',
    'settings_dns_desc': 'Via local VPN (always active when running)',
    'settings_track_all_apps': 'Track All Apps',
    'settings_track_all_apps_on': 'Monitoring all app traffic',
    'settings_track_all_apps_off': 'Only monitoring browser apps',
    'settings_cloud_sync': 'Cloud Sync',
    'settings_sync_status': 'Sync Status',
    'settings_syncing': 'Syncing...',
    'settings_last_sync': 'Last: @time',
    'settings_never_synced': 'Never synced',
    'settings_pending': 'Pending Records',
    'settings_pending_count': '@count records',
    'settings_privacy': 'Privacy',
    'settings_data_retention': 'Data Retention',
    'settings_days': '@count days',
    'settings_danger': 'Danger Zone',
    'settings_delete_data': 'Delete Browsing Data',
    'settings_delete_data_desc': 'Remove all monitored activity',
    'settings_delete_account': 'Delete Account',
    'settings_delete_account_desc': 'Remove account and all data',
    'settings_sign_out': 'Sign Out',
    'settings_version': 'Mindsafe v1.0.0',
    'settings_updated': 'Updated',
    'settings_retention_set': 'Data retention set to @count days',

    // ─── Sheet descriptions ───
    'sheet_theme_desc':
        'Choose how the app looks. Your preference is saved and applied instantly.',
    'sheet_theme_light_desc': 'Bright, clean interface for daytime use',
    'sheet_theme_dark_desc': 'Darker tones to reduce eye strain at night',
    'sheet_theme_system_desc': 'Automatically match your device settings',
    'sheet_language_desc':
        'Choose your preferred language. The change is applied immediately.',
    'sheet_language_en_desc': 'Use the app in English',
    'sheet_language_id_desc': 'Gunakan aplikasi dalam Bahasa Indonesia',
    'sheet_track_apps_desc':
        'Choose which apps to include in browsing monitoring.',
    'sheet_track_on_desc': 'Monitor browsing activity from all installed apps',
    'sheet_track_off_desc': 'Only monitor activity from web browsers',
    'sheet_retention_desc':
        'Choose how long browsing data is stored before being automatically deleted.',
    'sheet_retention_option_desc': 'Keep browsing records for @count days',

    // ─── About ───
    'about_section': 'About App',
    'about_check_update': 'Check for Updates',
    'about_share': 'Share App',
    'about_share_text':
        'Try Mindsafe – a safe browsing monitoring app for peace of mind! Download here:',
    'about_faq': 'FAQ',
    'about_feedback': 'Give Feedback',
    'about_social': 'Follow Our Social Media',
    'about_version': 'Version 1.0.0',
    'about_tagline': 'Safe browsing monitoring for peace of mind',
    'about_privacy_policy': 'Privacy Policy',
    'about_privacy_content':
        'Mindsafe is designed with your privacy in mind.\n\n'
        '1. Data Collection\n'
        'Mindsafe monitors domain names and URLs visited through a local VPN and Accessibility Service. '
        'All data is stored locally on your device and only synced to our secure servers with your consent.\n\n'
        '2. Data Usage\n'
        'Browsing data is used solely to provide monitoring insights to you and your designated guardians. '
        'We do not sell, share, or use your data for advertising purposes.\n\n'
        '3. Data Storage\n'
        'Your data is encrypted at rest and in transit. You can delete all browsing data at any time from Settings.\n\n'
        '4. Third-Party Access\n'
        'Only users you explicitly authorize as guardians can view your browsing activity summary. '
        'No third parties have access to your data.\n\n'
        '5. Your Rights\n'
        'You have the right to access, export, and delete your data at any time. '
        'You can also delete your account, which will remove all associated data permanently.',
    'about_terms': 'Terms & Conditions',
    'about_terms_content':
        'By using Mindsafe, you agree to the following terms:\n\n'
        '1. Purpose\n'
        'Mindsafe is a browsing monitoring tool designed to promote safe internet usage. '
        'It is intended for use with the knowledge and consent of the monitored user.\n\n'
        '2. Acceptable Use\n'
        'You agree to use Mindsafe only for its intended purpose of monitoring browsing habits '
        'for digital wellness and safety. Misuse of the app for unauthorized surveillance is prohibited.\n\n'
        '3. Accuracy\n'
        'While Mindsafe strives to provide accurate monitoring data, we do not guarantee '
        '100% accuracy in domain classification or URL capture.\n\n'
        '4. Liability\n'
        'Mindsafe is provided as-is. We are not liable for any damages arising from the use '
        'or inability to use the application.\n\n'
        '5. Changes\n'
        'We may update these terms from time to time. Continued use of the app constitutes '
        'acceptance of the updated terms.',
    'faq_q1': 'How does monitoring work?',
    'faq_a1':
        'Mindsafe uses two methods to monitor browsing activity:\n\n'
        '• VPN Service: Creates a local VPN on your device to intercept DNS queries. '
        'This captures which domains are being accessed by all apps.\n\n'
        '• Accessibility Service: Reads the URL from your browser address bar '
        'to provide more detailed, page-level tracking.\n\n'
        'Both methods work entirely on your device — no data leaves your phone without your permission.',
    'faq_q2': 'Does the app read my messages or content?',
    'faq_a2':
        'No. Mindsafe only monitors domain names (e.g., "google.com") and browser URLs. '
        'It does not read, intercept, or store any page content, messages, passwords, '
        'photos, or any other personal data. The VPN only processes DNS queries, '
        'not the actual data you send or receive.',
    'faq_q3': 'Why does it use a local VPN?',
    'faq_a3':
        'The local VPN is a technical method that allows Mindsafe to intercept DNS queries '
        'without requiring root access to your device. Unlike traditional VPNs:\n\n'
        '• It does NOT route your traffic through external servers\n'
        '• It does NOT slow down your internet connection\n'
        '• It runs entirely on your device\n'
        '• It only looks at DNS requests to identify which domains are being visited',
    'faq_q4': 'How is my data secured?',
    'faq_a4':
        'Your data security is our top priority:\n\n'
        '• All data is stored locally in an encrypted database on your device\n'
        '• Cloud sync (if enabled) uses end-to-end encryption\n'
        '• You can delete all data at any time from Settings\n'
        '• Only authorized guardians can view activity summaries\n'
        '• No third parties ever access your raw browsing data',
    'faq_q5': 'Why are some websites not detected?',
    'faq_a5':
        'If your browser uses a custom DNS (Secure DNS / DNS over HTTPS), '
        'domain queries bypass the local VPN and Mindsafe cannot detect them.\n\n'
        'To fix this, disable custom DNS in your browser:\n\n'
        '🔹 Google Chrome\n'
        '1. Open Chrome > tap ⋮ menu > Settings\n'
        '2. Go to Privacy and Security\n'
        '3. Tap "Use Secure DNS"\n'
        '4. Turn it OFF\n\n'
        '🔹 Mozilla Firefox\n'
        '1. Open Firefox > tap ☰ menu > Settings\n'
        '2. Scroll to "Enhanced DNS Privacy"\n'
        '3. Select "Off"\n\n'
        '🔹 Microsoft Edge\n'
        '1. Open Edge > tap ⋯ menu > Settings\n'
        '2. Go to Privacy and Security\n'
        '3. Tap "Use Secure DNS"\n'
        '4. Turn it OFF\n\n'
        '🔹 Opera / Brave\n'
        '1. Open Settings > Privacy\n'
        '2. Find "Secure DNS" or "DNS over HTTPS"\n'
        '3. Turn it OFF\n\n'
        'After disabling, restart your browser. Mindsafe will now detect all visited domains correctly.',

    // ─── Dialogs ───
    'dialog_cancel': 'Cancel',
    'dialog_delete': 'Delete',
    'dialog_add': 'Add',
    'dialog_confirm_delete_data': 'Delete Browsing Data?',
    'dialog_confirm_delete_data_desc':
        'This will permanently delete all monitored activity. This cannot be undone.',
    'dialog_confirm_delete_account': 'Delete Account?',
    'dialog_confirm_delete_account_desc':
        'This will permanently delete your account and all associated data. This cannot be undone.',
    'dialog_confirm_sign_out': 'Sign Out?',
    'dialog_confirm_sign_out_desc':
        'Are you sure you want to sign out of your account?',
    'dialog_done': 'Done',
    'dialog_all_data_deleted': 'All browsing data deleted',
    'dialog_error': 'Error',
    'dialog_delete_failed': 'Failed to delete account: @error',

    // ─── Toasts ───
    'toast_monitoring_started': 'Monitoring Started',
    'toast_monitoring_started_desc': 'DNS + URL monitoring is now active',
    'toast_monitoring_stopped': 'Monitoring Stopped',
    'toast_monitoring_stopped_desc': 'DNS + URL monitoring is now inactive',
    'toast_enable_url_monitoring': 'Enable URL Monitoring',
    'toast_enable_url_monitoring_desc':
        'Tap accessibility settings to enable full URL capture',
    'toast_vpn_error': 'Error',
    'toast_vpn_error_desc': 'Failed to start VPN. Please grant permission.',
    'toast_notif_enabled': 'Notifications Enabled',
    'toast_notif_enabled_desc': 'You will be alerted for unsafe domains',
    'toast_notif_disabled': 'Notifications Disabled',
    'toast_notif_disabled_desc': 'Unsafe domain alerts are turned off',
    'toast_notif_denied': 'Permission Required',
    'toast_notif_denied_desc':
        'Please allow notifications in system settings to enable alerts',

    // ─── Registration ───
    'reg_nickname_title': 'What should we call you?',
    'reg_nickname_desc': 'Enter a nickname for your profile',
    'reg_nickname_hint': 'Your nickname',
    'reg_age_title': 'How old are you?',
    'reg_age_desc': 'Select your age category',
    'reg_years': 'years',
    'reg_gender_title': 'What is your gender?',
    'reg_male': 'Male',
    'reg_female': 'Female',
    'reg_unspecified': 'Prefer not to say',
    'reg_retention_title': 'Data Retention',
    'reg_retention_desc': 'How long should we keep your browsing data?',
    'reg_days': 'days',
    'reg_default': 'default',
    'reg_consent_title': 'Monitoring Consent',
    'reg_consent_desc':
        'Mindsafe monitors your browsing activity (DNS queries and URLs) to help you stay aware of your digital habits. Your data is stored locally and synced securely.',
    'reg_consent_agree':
        'I agree to browsing monitoring for awareness purposes',
    'reg_next': 'Next',
    'reg_complete': 'Complete',
    'reg_error_save': 'Failed to save registration data',

    // ─── Onboarding ───
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_get_started': 'Get Started',
    'onboarding_title_1': 'Welcome to Mindsafe',
    'onboarding_desc_1':
        'Your personal browsing awareness companion. Monitor and understand your online habits.',
    'onboarding_title_2': 'DNS Monitoring',
    'onboarding_desc_2':
        'We use a local VPN to monitor DNS queries. No data leaves your device without your consent.',
    'onboarding_title_3': 'URL Tracking',
    'onboarding_desc_3':
        'Enable Accessibility Service to capture full URLs from browsers for better insights.',
    'onboarding_title_4': 'Your Privacy First',
    'onboarding_desc_4':
        'All data is stored locally. You control what gets synced to the cloud.',
    'onboarding_title_5': 'Smart Insights',
    'onboarding_desc_5':
        'Get weekly reports and identify browsing patterns to build healthier habits.',

    // ─── Login ───
    'login_title': 'Mindsafe',
    'login_subtitle': 'Monitor your browsing habits\nwith awareness',
    'login_google': 'Continue with Google',

    // ─── Admin ───
    'admin_title': 'Admin Panel',
    'admin_dashboard': 'Dashboard',
    'admin_rules': 'Rules',
    'admin_audit': 'Audit',
    'admin_system_overview': 'System Overview',
    'admin_total_users': 'Total Users',
    'admin_system_status': 'System Status',
    'admin_healthy': 'Healthy',
    'admin_quick_actions': 'Quick Actions',
    'admin_refresh': 'Refresh Stats',
    'admin_refreshing': 'Refreshing',
    'admin_fetching': 'Fetching latest stats...',
    'admin_add_rule': 'Add Rule',
    'admin_tab_rules': 'Rules',
    'admin_tab_skip': 'Skip',
    'admin_domain_pattern': 'Domain pattern',
    'admin_domain_hint': 'e.g. example.com',
    'admin_add_domain_rule': 'Add Domain Rule',
    'admin_rule_added': 'Added',
    'admin_rule_label': 'Rule: @pattern',
    'admin_no_audit': 'No audit logs yet',
    'admin_audit_desc': 'Admin actions will be logged here',
    'admin_notif': 'Notification',
    'admin_notif_compose': 'Compose Notification',
    'admin_notif_compose_desc': 'Send a push notification to all users',
    'admin_notif_type': 'Type',
    'admin_notif_title_label': 'Title',
    'admin_notif_title_hint': 'e.g. New Feature Available',
    'admin_notif_body_label': 'Message',
    'admin_notif_body_hint': 'Write your notification message here...',
    'admin_notif_send': 'Send',
    'admin_notif_history': 'Notification History',
    'admin_notif_empty': 'No notifications sent yet',
    'admin_notif_sent': 'Notification Sent',
    'admin_notif_fill_all': 'Please fill in both title and message',
    'admin_confirm_delete_notif_desc':
        'Are you sure you want to delete the notification "@title"?',
    'admin_total_domains': 'Total Domains',
    'admin_total_rules': 'Domain Rules',
    'admin_today_activity': 'Today\'s Activity',
    'admin_accesses': 'Accesses',
    'admin_hours': 'Hours',
    'admin_category_breakdown': 'Category Breakdown',
    'admin_recent_activity': 'Recent Activity',
    'admin_no_data': 'No data available',
    'admin_skip_rules': 'Skip Domains',
    'admin_add_skip': 'Add Skip',
    'admin_skip_desc': 'All subdomains will be skipped',
    'admin_skip_explanation':
        'Domains added here will be completely ignored during monitoring. All subdomains will also be skipped.',
    'admin_skip_domain_label': 'Domain',
    'admin_skip_hint': 'e.g. gopretstudio.com',
    'admin_no_skip_rules': 'No skip domains added',
    'admin_priority': 'Priority',
    'admin_confirm_delete': 'Delete Rule?',
    'admin_confirm_delete_rule_desc':
        'Are you sure you want to delete the rule for "@pattern"?',
    'admin_confirm_delete_skip_desc':
        'Are you sure you want to remove "@domain" from skip list?',
    'admin_delete': 'Delete',

    // ─── Categories ───
    'category_safe': 'Safe',
    'category_mixed': 'Mixed',
    'category_adult': 'Adult',
    'category_gambling': 'Gambling',
    'category_phishing': 'Phishing',
    'category_malware': 'Malware',
    'category_cryptojacking': 'Cryptojacking',
    'category_drugs': 'Drugs',
    'category_hacking': 'Hacking',
    'category_dangerous': 'Dangerous',
    'category_dating': 'Dating',
    'category_ddos': 'DDoS',
    'category_warez': 'Warez',

    // ─── VPN ───
    'vpn_started': 'Monitoring Started',
    'vpn_started_desc': 'DNS + URL monitoring is now active',
    'vpn_stopped': 'Monitoring Stopped',
    'vpn_stopped_desc': 'DNS + URL monitoring is now inactive',
    'vpn_error': 'VPN Error',
    'vpn_failed': 'Failed to start VPN. Please grant permission.',
    'vpn_enable_url': 'Enable URL Monitoring',
    'vpn_enable_url_desc':
        'Tap to enable Accessibility Service for full URL capture',

    // ─── Splash ───
    'splash_tagline': 'Browsing Awareness',
    'splash_loading_database': 'Loading data...',
    'splash_loading_auth': 'Checking authentication...',
    'splash_loading_vpn': 'Preparing VPN...',
    'splash_loading_classifier': 'Loading classifier...',
    'splash_loading_services': 'Starting services...',
    'splash_loading_cleanup': 'Cleaning up...',
    'splash_loading_ready': 'Almost ready...',

    // ─── Version ───
    'version_update_available': 'Update Available',
    'version_new_version': 'Version @version is available!',
    'version_current': 'Your current version: @version',
    'version_whats_new': "What's New:",
    'version_force_update':
        'This update is required to continue using the app.',
    'version_later': 'Later',
    'version_update_now': 'Update Now',
    'admin_version': 'Version',
    'admin_publish_version': 'Publish Version',
    'admin_version_number': 'Version Number',
    'admin_version_hint': 'e.g. 1.1.0',
    'admin_release_notes': 'Release Notes',
    'admin_release_notes_hint': 'Describe what is new...',
    'admin_force_update': 'Force Update',
    'admin_force_update_desc': 'Users must update to continue',
    'admin_publish': 'Publish',
    'admin_version_published': 'Version published successfully!',
    'admin_current_version': 'Current App Version',
    'admin_latest_published': 'Latest Published',
  };

  static const Map<String, String> idID = {
    // ─── Navigation ───
    'nav_home': 'Beranda',
    'nav_insights': 'Wawasan',
    'nav_history': 'Riwayat',
    'nav_settings': 'Pengaturan',
    'nav_admin': 'Admin',

    // ─── Home Screen ───
    'home_greeting': 'Hai, @name 👋',
    'home_monitoring': 'Monitoring',
    'home_start': 'Mulai Monitoring',
    'home_stop': 'Hentikan Monitoring',
    'home_activate': 'Aktifkan',
    'home_deactivate': 'Nonaktifkan',
    'home_vpn_active': 'VPN Aktif',
    'home_vpn_inactive': 'VPN Nonaktif',
    'home_accessibility_warning': 'Layanan Aksesibilitas Belum Aktif',
    'home_accessibility_desc':
        'Aktifkan Layanan Aksesibilitas untuk monitoring URL secara lengkap di semua browser.',
    'home_enable': 'Aktifkan',
    'home_today_stats': 'Aktivitas Hari Ini',
    'home_domains': 'Domain',
    'home_duration': 'Durasi',
    'home_urls': 'URL',
    'home_minutes': 'mnt',
    'home_admin_badge': 'Admin',
    'home_quick_actions': 'Aksi Cepat',
    'home_view_history': 'Lihat Riwayat',
    'home_view_insights': 'Lihat Wawasan',
    'home_weekly_summary': 'Ringkasan Mingguan',
    'home_weekly_duration': 'Total Durasi',
    'home_last_7_days': '7 Hari Terakhir',
    'home_hours': 'j',
    'home_monitoring_active_for': 'Monitoring aktif selama @hours j hari ini',
    'home_no_activity': 'Belum ada aktivitas hari ini',
    'home_insight': 'Wawasan',
    'home_insight_up': 'Aktivitas meningkat dari kemarin',
    'home_insight_down': 'Aktivitas menurun dari kemarin',
    'home_insight_stable': 'Aktivitas stabil',
    'home_insight_new': 'Mulai monitoring untuk melihat wawasan',
    'home_from_yesterday': 'dari kemarin',
    'home_same_as_yesterday': 'Sama seperti kemarin',
    'home_services': 'Layanan',
    'home_vpn_service': 'Layanan VPN',
    'home_url_capture': 'Penangkapan URL',
    'home_active': 'Aktif',
    'home_inactive': 'Nonaktif',
    'home_protected': 'Browsing kamu sedang dipantau',
    'home_not_protected': 'Ketuk untuk mulai monitoring',
    'home_monitoring_all_active': 'Semua Monitoring Aktif',
    'home_monitoring_partial': 'Monitoring Sebagian',
    'home_monitoring_inactive': 'Monitoring Nonaktif',
    'home_monitoring_title': 'Pengaturan Monitoring',
    'home_monitoring_subtitle':
        'Atur bagaimana aktivitas browsing kamu dipantau',
    'home_vpn_desc':
        'Menangkap semua query DNS dari seluruh aplikasi di perangkat kamu.',
    'home_url_capture_desc':
        'Membaca URL dari address bar browser untuk pelacakan halaman yang lebih detail.',
    'home_top_domains': 'Top Domain',
    'home_today': 'Hari ini',
    'home_category_breakdown': 'Breakdown Kategori',
    'home_notification': 'Notifikasi',
    'home_notification_desc':
        'Dapatkan peringatan saat website tidak aman terdeteksi saat browsing.',

    // ─── History Screen ───
    'history_title': 'Riwayat',
    'history_empty': 'Belum ada riwayat browsing',
    'history_empty_desc': 'Mulai monitoring untuk melacak aktivitasmu',
    'history_daily': 'Harian',
    'history_weekly': 'Mingguan',
    'history_monthly': 'Bulanan',
    'history_daily_title': 'Aktivitas Hari Ini',
    'history_weekly_title': 'Aktivitas 7 Hari',
    'history_monthly_title': 'Aktivitas 30 Hari',
    'history_domains_count': '@count domain',
    'history_categories': 'Kategori',
    'history_timeline': 'Linimasa',
    'history_today': 'Hari Ini',
    'history_this_week': 'Minggu Ini',
    'history_this_month': 'Bulan Ini',
    'history_yesterday': 'Kemarin',
    'history_total': 'Total',
    'history_average': 'Rata-rata',
    'history_highest': 'Tertinggi',
    'history_top_domains': 'Domain Teratas',
    'history_visits': '@count kunjungan',
    'history_time_spent': 'Waktu Dihabiskan',
    'history_seconds': '@count dtk',
    'history_min_sec': '@min mnt @sec dtk',
    'history_hours_min': '@hrs jam @min mnt',
    'history_tab_overview': 'Ringkasan',
    'history_tab_calendar': 'Kalender',
    'history_calendar_detail': 'Detail Aktivitas',
    'history_calendar_accessed': 'domain diakses',
    'history_calendar_empty': 'Tidak ada aktivitas pada tanggal ini',

    // ─── Insights Screen ───
    'insights_title': 'Wawasan',
    'insights_empty': 'Wawasan Segera Hadir',
    'insights_empty_desc':
        'Mulai monitoring untuk wawasan yang dipersonalisasi',
    'insights_monitoring_active': 'Monitoring tetap aktif',
    'insights_summary': 'Ringkasan',
    'insights_total_domains': 'Total Domain',
    'insights_total_duration': 'Total Durasi',
    'insights_avg_daily': 'Rata-rata Harian',
    'insights_your_insights': 'Wawasan Kamu',
    'insights_high_activity': 'Aktivitas Tinggi',
    'insights_high_activity_desc':
        'Kamu mengunjungi @count domain unik. Pertimbangkan untuk mengurangi.',
    'insights_clean': 'Semua Aman',
    'insights_clean_desc':
        'Tidak ada aktivitas berisiko terdeteksi hari ini. Pertahankan!',
    'insights_adult_detected': 'Konten Dewasa Terdeteksi',
    'insights_adult_desc':
        '@count kunjungan ke situs konten dewasa terdeteksi.',
    'insights_mixed_detected': 'Konten Campuran',
    'insights_mixed_desc':
        '@count kunjungan ke situs konten campuran. Tinjau kebiasaan browsingmu.',
    'insights_extended_usage': 'Penggunaan Lama',
    'insights_extended_desc':
        'Kamu menghabiskan @mins menit browsing. Pertimbangkan istirahat.',
    'insights_low_activity': 'Aktivitas Rendah',
    'insights_low_activity_desc':
        'Hanya @count domain dikunjungi. Disiplin digital yang baik!',
    'insights_hours': 'jam',
    'insights_minutes': 'mnt',
    'insights_badge_today': 'Hari Ini',
    'insights_badge_weekly': 'Mingguan',
    'insights_badge_monthly': 'Bulanan',
    'insights_weekly_trend_up': 'Aktivitas Meningkat',
    'insights_weekly_trend_up_desc':
        'Aktivitas browsing naik @pct% dibanding minggu lalu.',
    'insights_weekly_trend_down': 'Aktivitas Menurun',
    'insights_weekly_trend_down_desc':
        'Aktivitas browsing turun @pct% dibanding minggu lalu.',
    'insights_weekly_avg': 'Rata-rata Mingguan',
    'insights_weekly_avg_desc':
        'Rata-rata @avg domain dikunjungi per hari minggu ini.',
    'insights_above_avg': 'Di Atas Rata-rata',
    'insights_above_avg_desc':
        'Hari ini kamu mengunjungi @today domain, di atas rata-rata harian @avg.',
    'insights_below_avg': 'Di Bawah Rata-rata',
    'insights_below_avg_desc':
        'Hari ini kamu mengunjungi @today domain, di bawah rata-rata harian @avg.',
    'insights_most_active_day': 'Hari Paling Aktif',
    'insights_most_active_day_desc':
        '@day adalah hari paling aktif browsingmu minggu ini.',
    'insights_day_mon': 'Senin',
    'insights_day_tue': 'Selasa',
    'insights_day_wed': 'Rabu',
    'insights_day_thu': 'Kamis',
    'insights_day_fri': 'Jumat',
    'insights_day_sat': 'Sabtu',
    'insights_day_sun': 'Minggu',
    'insights_monthly_domains': 'Ringkasan Bulanan',
    'insights_monthly_domains_desc':
        '@count domain unik dikunjungi dengan @visits total kunjungan bulan ini.',
    'insights_monthly_duration': 'Waktu Layar Bulanan',
    'insights_monthly_duration_desc':
        'Kamu menghabiskan sekitar @hours jam browsing bulan ini.',

    // ─── Settings Screen ───
    'settings_title': 'Pengaturan',
    'settings_appearance': 'Tampilan',
    'settings_theme': 'Tema',
    'settings_theme_light': 'Terang',
    'settings_theme_dark': 'Gelap',
    'settings_theme_system': 'Sistem',
    'settings_language': 'Bahasa',
    'settings_language_en': 'English',
    'settings_language_id': 'Bahasa Indonesia',
    'settings_monitoring': 'Monitoring',
    'settings_url_monitoring': 'Monitoring URL',
    'settings_url_enabled': 'Aktif',
    'settings_url_disabled': 'Nonaktif - Ketuk untuk mengaktifkan',
    'settings_dns_monitoring': 'Monitoring DNS',
    'settings_dns_desc': 'Melalui VPN lokal (selalu aktif saat berjalan)',
    'settings_track_all_apps': 'Pantau Semua Aplikasi',
    'settings_track_all_apps_on': 'Memantau semua lalu lintas aplikasi',
    'settings_track_all_apps_off': 'Hanya memantau aplikasi browser',
    'settings_cloud_sync': 'Sinkronisasi Cloud',
    'settings_sync_status': 'Status Sinkronisasi',
    'settings_syncing': 'Menyinkronkan...',
    'settings_last_sync': 'Terakhir: @time',
    'settings_never_synced': 'Belum pernah disinkronkan',
    'settings_pending': 'Rekaman Tertunda',
    'settings_pending_count': '@count rekaman',
    'settings_privacy': 'Privasi',
    'settings_data_retention': 'Retensi Data',
    'settings_days': '@count hari',
    'settings_danger': 'Zona Bahaya',
    'settings_delete_data': 'Hapus Data Browsing',
    'settings_delete_data_desc': 'Hapus semua aktivitas yang dipantau',
    'settings_delete_account': 'Hapus Akun',
    'settings_delete_account_desc': 'Hapus akun dan semua data',
    'settings_sign_out': 'Keluar',
    'settings_version': 'Mindsafe v1.0.0',
    'settings_updated': 'Diperbarui',
    'settings_retention_set': 'Retensi data diatur ke @count hari',

    // ─── Sheet descriptions ───
    'sheet_theme_desc':
        'Pilih tampilan aplikasi. Preferensi Anda disimpan dan diterapkan langsung.',
    'sheet_theme_light_desc':
        'Tampilan cerah dan bersih untuk penggunaan siang hari',
    'sheet_theme_dark_desc':
        'Warna gelap untuk mengurangi kelelahan mata di malam hari',
    'sheet_theme_system_desc':
        'Ikuti pengaturan tema perangkat secara otomatis',
    'sheet_language_desc':
        'Pilih bahasa yang Anda inginkan. Perubahan diterapkan langsung.',
    'sheet_language_en_desc': 'Use the app in English',
    'sheet_language_id_desc': 'Gunakan aplikasi dalam Bahasa Indonesia',
    'sheet_track_apps_desc':
        'Pilih aplikasi mana yang dimasukkan dalam monitoring browsing.',
    'sheet_track_on_desc':
        'Pantau aktivitas browsing dari semua aplikasi yang terinstal',
    'sheet_track_off_desc': 'Hanya pantau aktivitas dari browser web',
    'sheet_retention_desc':
        'Pilih berapa lama data browsing disimpan sebelum dihapus otomatis.',
    'sheet_retention_option_desc': 'Simpan catatan browsing selama @count hari',

    // ─── About ───
    'about_section': 'Tentang Aplikasi',
    'about_check_update': 'Periksa Pembaruan',
    'about_share': 'Bagikan Aplikasi',
    'about_share_text':
        'Coba Mindsafe – aplikasi monitoring browsing aman untuk ketenangan pikiran! Download di sini:',
    'about_faq': 'Pertanyaan Umum',
    'about_feedback': 'Beri Masukan',
    'about_social': 'Ikuti Media Sosial Kami',
    'about_version': 'Versi 1.0.0',
    'about_tagline': 'Monitoring browsing aman untuk ketenangan pikiran',
    'about_privacy_policy': 'Kebijakan Privasi',
    'about_privacy_content':
        'Mindsafe dirancang dengan mengutamakan privasi Anda.\n\n'
        '1. Pengumpulan Data\n'
        'Mindsafe memantau nama domain dan URL yang dikunjungi melalui VPN lokal dan Layanan Aksesibilitas. '
        'Semua data disimpan secara lokal di perangkat Anda dan hanya disinkronkan ke server kami dengan persetujuan Anda.\n\n'
        '2. Penggunaan Data\n'
        'Data browsing hanya digunakan untuk memberikan wawasan monitoring kepada Anda dan wali yang Anda tunjuk. '
        'Kami tidak menjual, membagikan, atau menggunakan data Anda untuk tujuan iklan.\n\n'
        '3. Penyimpanan Data\n'
        'Data Anda dienkripsi saat disimpan dan saat dikirim. Anda dapat menghapus semua data browsing kapan saja dari Pengaturan.\n\n'
        '4. Akses Pihak Ketiga\n'
        'Hanya pengguna yang Anda otorisasi secara eksplisit sebagai wali yang dapat melihat ringkasan aktivitas browsing Anda. '
        'Tidak ada pihak ketiga yang memiliki akses ke data Anda.\n\n'
        '5. Hak Anda\n'
        'Anda berhak mengakses, mengekspor, dan menghapus data Anda kapan saja. '
        'Anda juga dapat menghapus akun, yang akan menghapus semua data terkait secara permanen.',
    'about_terms': 'Syarat & Ketentuan',
    'about_terms_content':
        'Dengan menggunakan Mindsafe, Anda menyetujui ketentuan berikut:\n\n'
        '1. Tujuan\n'
        'Mindsafe adalah alat monitoring browsing yang dirancang untuk mendorong penggunaan internet yang aman. '
        'Ini ditujukan untuk digunakan dengan sepengetahuan dan persetujuan pengguna yang dipantau.\n\n'
        '2. Penggunaan yang Diizinkan\n'
        'Anda setuju untuk menggunakan Mindsafe hanya untuk tujuan yang dimaksudkan yaitu memantau kebiasaan browsing '
        'untuk kesehatan digital dan keamanan. Penyalahgunaan aplikasi untuk pengawasan yang tidak sah dilarang.\n\n'
        '3. Akurasi\n'
        'Meskipun Mindsafe berusaha menyediakan data monitoring yang akurat, kami tidak menjamin '
        'akurasi 100% dalam klasifikasi domain atau penangkapan URL.\n\n'
        '4. Tanggung Jawab\n'
        'Mindsafe disediakan apa adanya. Kami tidak bertanggung jawab atas kerusakan yang timbul dari penggunaan '
        'atau ketidakmampuan menggunakan aplikasi.\n\n'
        '5. Perubahan\n'
        'Kami dapat memperbarui ketentuan ini dari waktu ke waktu. Penggunaan lanjutan dari aplikasi merupakan '
        'penerimaan atas ketentuan yang diperbarui.',
    'faq_q1': 'Bagaimana cara kerja monitoring?',
    'faq_a1':
        'Mindsafe menggunakan dua metode untuk memantau aktivitas browsing:\n\n'
        '• Layanan VPN: Membuat VPN lokal di perangkat Anda untuk menangkap query DNS. '
        'Ini menangkap domain mana yang diakses oleh semua aplikasi.\n\n'
        '• Layanan Aksesibilitas: Membaca URL dari address bar browser Anda '
        'untuk pelacakan halaman yang lebih detail.\n\n'
        'Kedua metode bekerja sepenuhnya di perangkat Anda — tidak ada data yang keluar dari ponsel tanpa izin Anda.',
    'faq_q2': 'Apakah aplikasi membaca pesan atau konten saya?',
    'faq_a2':
        'Tidak. Mindsafe hanya memantau nama domain (misalnya, "google.com") dan URL browser. '
        'Aplikasi tidak membaca, menyadap, atau menyimpan konten halaman, pesan, kata sandi, '
        'foto, atau data pribadi lainnya. VPN hanya memproses query DNS, '
        'bukan data aktual yang Anda kirim atau terima.',
    'faq_q3': 'Mengapa menggunakan VPN lokal?',
    'faq_a3':
        'VPN lokal adalah metode teknis yang memungkinkan Mindsafe menangkap query DNS '
        'tanpa memerlukan akses root ke perangkat Anda. Berbeda dengan VPN tradisional:\n\n'
        '• TIDAK merutekan lalu lintas Anda melalui server eksternal\n'
        '• TIDAK memperlambat koneksi internet Anda\n'
        '• Berjalan sepenuhnya di perangkat Anda\n'
        '• Hanya melihat permintaan DNS untuk mengidentifikasi domain mana yang dikunjungi',
    'faq_q4': 'Bagaimana keamanan data saya?',
    'faq_a4':
        'Keamanan data Anda adalah prioritas utama kami:\n\n'
        '• Semua data disimpan secara lokal dalam database terenkripsi di perangkat Anda\n'
        '• Sinkronisasi cloud (jika diaktifkan) menggunakan enkripsi end-to-end\n'
        '• Anda dapat menghapus semua data kapan saja dari Pengaturan\n'
        '• Hanya wali yang diotorisasi yang dapat melihat ringkasan aktivitas\n'
        '• Tidak ada pihak ketiga yang pernah mengakses data browsing mentah Anda',
    'faq_q5': 'Mengapa beberapa website tidak terdeteksi?',
    'faq_a5':
        'Jika browser kamu menggunakan DNS kustom (Secure DNS / DNS over HTTPS), '
        'query domain akan melewati VPN lokal sehingga Mindsafe tidak bisa mendeteksinya.\n\n'
        'Untuk mengatasinya, matikan DNS kustom di browser:\n\n'
        '🔹 Google Chrome\n'
        '1. Buka Chrome > ketuk menu ⋮ > Setelan\n'
        '2. Masuk ke Privasi dan Keamanan\n'
        '3. Ketuk "Gunakan DNS Aman"\n'
        '4. Matikan\n\n'
        '🔹 Mozilla Firefox\n'
        '1. Buka Firefox > ketuk menu ☰ > Pengaturan\n'
        '2. Gulir ke "Privasi DNS Ditingkatkan"\n'
        '3. Pilih "Nonaktif"\n\n'
        '🔹 Microsoft Edge\n'
        '1. Buka Edge > ketuk menu ⋯ > Pengaturan\n'
        '2. Masuk ke Privasi dan Keamanan\n'
        '3. Ketuk "Gunakan DNS Aman"\n'
        '4. Matikan\n\n'
        '🔹 Opera / Brave\n'
        '1. Buka Pengaturan > Privasi\n'
        '2. Cari "DNS Aman" atau "DNS over HTTPS"\n'
        '3. Matikan\n\n'
        'Setelah dimatikan, restart browser. Mindsafe sekarang akan mendeteksi semua domain yang dikunjungi dengan benar.',

    // ─── Dialogs ───
    'dialog_cancel': 'Batal',
    'dialog_delete': 'Hapus',
    'dialog_add': 'Tambah',
    'dialog_confirm_delete_data': 'Hapus Data Browsing?',
    'dialog_confirm_delete_data_desc':
        'Ini akan menghapus semua aktivitas yang dipantau secara permanen. Tidak dapat dikembalikan.',
    'dialog_confirm_delete_account': 'Hapus Akun?',
    'dialog_confirm_delete_account_desc':
        'Ini akan menghapus akun dan semua data terkait secara permanen. Tidak dapat dikembalikan.',
    'dialog_confirm_sign_out': 'Keluar?',
    'dialog_confirm_sign_out_desc':
        'Apakah kamu yakin ingin keluar dari akunmu?',
    'dialog_done': 'Selesai',
    'dialog_all_data_deleted': 'Semua data browsing dihapus',
    'dialog_error': 'Kesalahan',
    'dialog_delete_failed': 'Gagal menghapus akun: @error',

    // ─── Toasts ───
    'toast_monitoring_started': 'Monitoring Aktif',
    'toast_monitoring_started_desc': 'Monitoring DNS + URL sekarang aktif',
    'toast_monitoring_stopped': 'Monitoring Berhenti',
    'toast_monitoring_stopped_desc': 'Monitoring DNS + URL sekarang nonaktif',
    'toast_enable_url_monitoring': 'Aktifkan Monitoring URL',
    'toast_enable_url_monitoring_desc':
        'Buka pengaturan aksesibilitas untuk mengaktifkan tangkapan URL lengkap',
    'toast_vpn_error': 'Kesalahan',
    'toast_vpn_error_desc': 'Gagal memulai VPN. Mohon berikan izin.',
    'toast_notif_enabled': 'Notifikasi Diaktifkan',
    'toast_notif_enabled_desc':
        'Kamu akan diperingatkan untuk domain tidak aman',
    'toast_notif_disabled': 'Notifikasi Dinonaktifkan',
    'toast_notif_disabled_desc': 'Peringatan domain tidak aman dimatikan',
    'toast_notif_denied': 'Izin Diperlukan',
    'toast_notif_denied_desc':
        'Izinkan notifikasi di pengaturan sistem untuk mengaktifkan peringatan',

    // ─── Registration ───
    'reg_nickname_title': 'Mau dipanggil apa?',
    'reg_nickname_desc': 'Masukkan nama panggilan untuk profilmu',
    'reg_nickname_hint': 'Nama panggilanmu',
    'reg_age_title': 'Berapa usiamu?',
    'reg_age_desc': 'Pilih kategori usia',
    'reg_years': 'tahun',
    'reg_gender_title': 'Apa jenis kelaminmu?',
    'reg_male': 'Laki-laki',
    'reg_female': 'Perempuan',
    'reg_unspecified': 'Tidak ingin menjawab',
    'reg_retention_title': 'Retensi Data',
    'reg_retention_desc': 'Berapa lama data browsing harus disimpan?',
    'reg_days': 'hari',
    'reg_default': 'default',
    'reg_consent_title': 'Persetujuan Monitoring',
    'reg_consent_desc':
        'Mindsafe memantau aktivitas browsing (query DNS dan URL) untuk membantu kesadaran kebiasaan digitalmu. Data disimpan lokal dan disinkronkan secara aman.',
    'reg_consent_agree':
        'Saya setuju dengan pemantauan browsing untuk tujuan kesadaran',
    'reg_next': 'Selanjutnya',
    'reg_complete': 'Selesai',
    'reg_error_save': 'Gagal menyimpan data registrasi',

    // ─── Onboarding ───
    'onboarding_skip': 'Lewati',
    'onboarding_next': 'Lanjut',
    'onboarding_get_started': 'Mulai',
    'onboarding_title_1': 'Selamat Datang di Mindsafe',
    'onboarding_desc_1':
        'Teman kesadaran browsing pribadimu. Pantau dan pahami kebiasaan online-mu.',
    'onboarding_title_2': 'Monitoring DNS',
    'onboarding_desc_2':
        'Kami menggunakan VPN lokal untuk memantau query DNS. Tidak ada data yang keluar tanpa persetujuanmu.',
    'onboarding_title_3': 'Pelacakan URL',
    'onboarding_desc_3':
        'Aktifkan Layanan Aksesibilitas untuk menangkap URL lengkap dari browser untuk wawasan yang lebih baik.',
    'onboarding_title_4': 'Privasi Utama',
    'onboarding_desc_4':
        'Semua data disimpan secara lokal. Kamu yang mengontrol apa yang disinkronkan ke cloud.',
    'onboarding_title_5': 'Wawasan Cerdas',
    'onboarding_desc_5':
        'Dapatkan laporan mingguan dan identifikasi pola browsing untuk membangun kebiasaan yang lebih sehat.',

    // ─── Login ───
    'login_title': 'Mindsafe',
    'login_subtitle': 'Pantau kebiasaan browsingmu\ndengan kesadaran',
    'login_google': 'Lanjutkan dengan Google',

    // ─── Admin ───
    'admin_title': 'Panel Admin',
    'admin_dashboard': 'Dasbor',
    'admin_rules': 'Aturan',
    'admin_audit': 'Audit',
    'admin_system_overview': 'Gambaran Sistem',
    'admin_total_users': 'Total Pengguna',
    'admin_system_status': 'Status Sistem',
    'admin_healthy': 'Sehat',
    'admin_quick_actions': 'Aksi Cepat',
    'admin_refresh': 'Perbarui Stats',
    'admin_refreshing': 'Memperbarui',
    'admin_fetching': 'Mengambil statistik terbaru...',
    'admin_add_rule': 'Tambah Aturan',
    'admin_tab_rules': 'Aturan',
    'admin_tab_skip': 'Skip',
    'admin_domain_pattern': 'Pola domain',
    'admin_domain_hint': 'cth. example.com',
    'admin_add_domain_rule': 'Tambah Aturan Domain',
    'admin_rule_added': 'Ditambahkan',
    'admin_rule_label': 'Aturan: @pattern',
    'admin_no_audit': 'Belum ada log audit',
    'admin_audit_desc': 'Aksi admin akan dicatat di sini',
    'admin_notif': 'Notifikasi',
    'admin_notif_compose': 'Buat Notifikasi',
    'admin_notif_compose_desc': 'Kirim notifikasi push ke semua pengguna',
    'admin_notif_type': 'Tipe',
    'admin_notif_title_label': 'Judul',
    'admin_notif_title_hint': 'cth. Fitur Baru Tersedia',
    'admin_notif_body_label': 'Pesan',
    'admin_notif_body_hint': 'Tulis pesan notifikasi di sini...',
    'admin_notif_send': 'Kirim',
    'admin_notif_history': 'Riwayat Notifikasi',
    'admin_notif_empty': 'Belum ada notifikasi yang dikirim',
    'admin_notif_sent': 'Notifikasi Terkirim',
    'admin_notif_fill_all': 'Mohon isi judul dan pesan',
    'admin_confirm_delete_notif_desc':
        'Apakah kamu yakin ingin menghapus notifikasi "@title"?',
    'admin_total_domains': 'Total Domain',
    'admin_total_rules': 'Aturan Domain',
    'admin_today_activity': 'Aktivitas Hari Ini',
    'admin_accesses': 'Akses',
    'admin_hours': 'Jam',
    'admin_category_breakdown': 'Rincian Kategori',
    'admin_recent_activity': 'Aktivitas Terakhir',
    'admin_no_data': 'Belum ada data',
    'admin_skip_rules': 'Domain yang Dilewati',
    'admin_add_skip': 'Tambah Skip',
    'admin_skip_desc': 'Semua subdomain akan dilewati',
    'admin_skip_explanation':
        'Domain yang ditambahkan di sini akan sepenuhnya diabaikan selama pemantauan. Semua subdomain juga akan dilewati.',
    'admin_skip_domain_label': 'Domain',
    'admin_skip_hint': 'cth. gopretstudio.com',
    'admin_no_skip_rules': 'Belum ada domain yang dilewati',
    'admin_priority': 'Prioritas',
    'admin_confirm_delete': 'Hapus Aturan?',
    'admin_confirm_delete_rule_desc':
        'Apakah kamu yakin ingin menghapus aturan untuk "@pattern"?',
    'admin_confirm_delete_skip_desc':
        'Apakah kamu yakin ingin menghapus "@domain" dari daftar skip?',
    'admin_delete': 'Hapus',

    // ─── Categories ───
    'category_safe': 'Aman',
    'category_mixed': 'Campuran',
    'category_adult': 'Dewasa',
    'category_gambling': 'Judi',
    'category_phishing': 'Penipuan',
    'category_malware': 'Malware',
    'category_cryptojacking': 'Cryptojacking',
    'category_drugs': 'Narkoba',
    'category_hacking': 'Hacking',
    'category_dangerous': 'Berbahaya',
    'category_dating': 'Kencan',
    'category_ddos': 'DDoS',
    'category_warez': 'Bajakan',

    // ─── VPN ───
    'vpn_started': 'Monitoring Dimulai',
    'vpn_started_desc': 'Monitoring DNS + URL sedang aktif',
    'vpn_stopped': 'Monitoring Dihentikan',
    'vpn_stopped_desc': 'Monitoring DNS + URL tidak aktif',
    'vpn_error': 'Kesalahan VPN',
    'vpn_failed': 'Gagal memulai VPN. Berikan izin.',
    'vpn_enable_url': 'Aktifkan Monitoring URL',
    'vpn_enable_url_desc':
        'Ketuk untuk mengaktifkan Layanan Aksesibilitas untuk menangkap URL',

    // ─── Splash ───
    'splash_tagline': 'Kesadaran Browsing',
    'splash_loading_database': 'Memuat data...',
    'splash_loading_auth': 'Memeriksa autentikasi...',
    'splash_loading_vpn': 'Menyiapkan VPN...',
    'splash_loading_classifier': 'Memuat pengklasifikasi...',
    'splash_loading_services': 'Memulai layanan...',
    'splash_loading_cleanup': 'Membersihkan...',
    'splash_loading_ready': 'Hampir siap...',

    // ─── Version ───
    'version_update_available': 'Pembaruan Tersedia',
    'version_new_version': 'Versi @version tersedia!',
    'version_current': 'Versi Anda saat ini: @version',
    'version_whats_new': 'Yang Baru:',
    'version_force_update':
        'Pembaruan ini wajib untuk melanjutkan penggunaan aplikasi.',
    'version_later': 'Nanti',
    'version_update_now': 'Perbarui Sekarang',
    'admin_version': 'Versi',
    'admin_publish_version': 'Publikasikan Versi',
    'admin_version_number': 'Nomor Versi',
    'admin_version_hint': 'contoh: 1.1.0',
    'admin_release_notes': 'Catatan Rilis',
    'admin_release_notes_hint': 'Jelaskan apa yang baru...',
    'admin_force_update': 'Paksa Pembaruan',
    'admin_force_update_desc': 'Pengguna harus memperbarui untuk melanjutkan',
    'admin_publish': 'Publikasikan',
    'admin_version_published': 'Versi berhasil dipublikasikan!',
    'admin_current_version': 'Versi Aplikasi Saat Ini',
    'admin_latest_published': 'Terakhir Dipublikasikan',
  };
}
