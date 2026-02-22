import 'package:flutter_test/flutter_test.dart';
import 'package:mindsafe_flutter/data/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('creates with default values', () {
      final settings = AppSettings();

      expect(settings.dataRetentionDays, 30);
      expect(settings.hashDomains, false);
      expect(settings.themeMode, 'system');
      expect(settings.notificationsEnabled, true);
    });

    test('creates with custom values', () {
      final settings = AppSettings(
        dataRetentionDays: 90,
        hashDomains: true,
        themeMode: 'dark',
        notificationsEnabled: false,
      );

      expect(settings.dataRetentionDays, 90);
      expect(settings.hashDomains, true);
      expect(settings.themeMode, 'dark');
      expect(settings.notificationsEnabled, false);
    });

    test('toMap produces correct output', () {
      final settings = AppSettings(
        dataRetentionDays: 7,
        hashDomains: true,
        themeMode: 'light',
        notificationsEnabled: false,
      );

      final map = settings.toMap();

      expect(map['dataRetentionDays'], 7);
      expect(map['hashDomains'], true);
      expect(map['themeMode'], 'light');
      expect(map['notificationsEnabled'], false);
    });

    test('fromMap creates correct instance', () {
      final map = {
        'dataRetentionDays': 14,
        'hashDomains': false,
        'themeMode': 'dark',
        'notificationsEnabled': true,
      };

      final settings = AppSettings.fromMap(map);

      expect(settings.dataRetentionDays, 14);
      expect(settings.hashDomains, false);
      expect(settings.themeMode, 'dark');
      expect(settings.notificationsEnabled, true);
    });

    test('fromMap provides defaults for missing fields', () {
      final settings = AppSettings.fromMap({});

      expect(settings.dataRetentionDays, 30);
      expect(settings.hashDomains, false);
      expect(settings.themeMode, 'system');
      expect(settings.notificationsEnabled, true);
    });

    test('toMap and fromMap roundtrip', () {
      final original = AppSettings(
        dataRetentionDays: 60,
        hashDomains: true,
        themeMode: 'light',
        notificationsEnabled: false,
      );

      final reconstructed = AppSettings.fromMap(original.toMap());

      expect(reconstructed.dataRetentionDays, original.dataRetentionDays);
      expect(reconstructed.hashDomains, original.hashDomains);
      expect(reconstructed.themeMode, original.themeMode);
      expect(reconstructed.notificationsEnabled, original.notificationsEnabled);
    });

    test('supports valid retention day values', () {
      for (final days in [7, 14, 30, 60, 90]) {
        final settings = AppSettings(dataRetentionDays: days);
        expect(settings.dataRetentionDays, days);
      }
    });

    test('supports valid theme modes', () {
      for (final mode in ['light', 'dark', 'system']) {
        final settings = AppSettings(themeMode: mode);
        expect(settings.themeMode, mode);
      }
    });

    test('fields are mutable', () {
      final settings = AppSettings();

      settings.dataRetentionDays = 7;
      settings.hashDomains = true;
      settings.themeMode = 'dark';
      settings.notificationsEnabled = false;

      expect(settings.dataRetentionDays, 7);
      expect(settings.hashDomains, true);
      expect(settings.themeMode, 'dark');
      expect(settings.notificationsEnabled, false);
    });
  });
}
