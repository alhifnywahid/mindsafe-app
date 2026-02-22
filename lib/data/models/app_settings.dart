import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  int dataRetentionDays; // 7, 30, or 90

  @HiveField(1)
  bool hashDomains; // Privacy mode: true = hash domains

  @HiveField(2)
  String themeMode; // light, dark, system

  @HiveField(3)
  bool notificationsEnabled;

  AppSettings({
    this.dataRetentionDays = 30,
    this.hashDomains = false,
    this.themeMode = 'system',
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'dataRetentionDays': dataRetentionDays,
      'hashDomains': hashDomains,
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      dataRetentionDays: map['dataRetentionDays'] ?? 30,
      hashDomains: map['hashDomains'] ?? false,
      themeMode: map['themeMode'] ?? 'system',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}
