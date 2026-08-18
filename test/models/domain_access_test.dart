import 'package:flutter_test/flutter_test.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';

void main() {
  group('DomainAccess', () {
    test('creates with required fields', () {
      final access = DomainAccess(
        domain: 'example.com',
        timestamp: DateTime(2026, 1, 1, 12, 0),
        userId: 'user123',
      );

      expect(access.domain, 'example.com');
      expect(access.timestamp, DateTime(2026, 1, 1, 12, 0));
      expect(access.userId, 'user123');
      expect(access.durationSeconds, 0); // default
      expect(access.category, 'safe'); // default
      expect(access.synced, false); // default
    });

    test('creates with all fields', () {
      final access = DomainAccess(
        domain: 'google.com',
        timestamp: DateTime(2026, 2, 15, 10, 30),
        durationSeconds: 120,
        category: 'safe',
        synced: true,
        userId: 'admin1',
      );

      expect(access.domain, 'google.com');
      expect(access.durationSeconds, 120);
      expect(access.category, 'safe');
      expect(access.synced, true);
      expect(access.userId, 'admin1');
    });

    test('toMap produces correct output', () {
      final now = DateTime(2026, 3, 1, 8, 0);
      final access = DomainAccess(
        domain: 'test.com',
        timestamp: now,
        durationSeconds: 60,
        category: 'mixed',
        synced: false,
        userId: 'u1',
      );

      final map = access.toMap();

      expect(map['domain'], 'test.com');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['durationSeconds'], 60);
      expect(map['category'], 'mixed');
      expect(map['synced'], false);
      expect(map['userId'], 'u1');
    });

    test('fromMap creates correct instance', () {
      final map = {
        'domain': 'flutter.dev',
        'timestamp': '2026-04-01T14:00:00.000',
        'durationSeconds': 300,
        'category': 'safe',
        'synced': true,
        'userId': 'user456',
      };

      final access = DomainAccess.fromMap(map);

      expect(access.domain, 'flutter.dev');
      expect(access.timestamp, DateTime(2026, 4, 1, 14, 0));
      expect(access.durationSeconds, 300);
      expect(access.category, 'safe');
      expect(access.synced, true);
      expect(access.userId, 'user456');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'domain': 'minimal.com',
        'timestamp': '2026-01-01T00:00:00.000',
      };

      final access = DomainAccess.fromMap(map);

      expect(access.domain, 'minimal.com');
      expect(access.durationSeconds, 0);
      expect(access.category, 'safe');
      expect(access.synced, false);
      expect(access.userId, '');
    });

    test('toMap and fromMap are reversible', () {
      final original = DomainAccess(
        domain: 'roundtrip.com',
        timestamp: DateTime(2026, 6, 15, 20, 30),
        durationSeconds: 45,
        category: 'adult',
        synced: true,
        userId: 'rt_user',
      );

      final reconstructed = DomainAccess.fromMap(original.toMap());

      expect(reconstructed.domain, original.domain);
      expect(reconstructed.durationSeconds, original.durationSeconds);
      expect(reconstructed.category, original.category);
      expect(reconstructed.synced, original.synced);
      expect(reconstructed.userId, original.userId);
    });
  });
}
