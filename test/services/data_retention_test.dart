import 'package:flutter_test/flutter_test.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';

/// Tests for data retention logic used in DataManager.enforceRetention.
/// Tests pure logic without requiring Hive initialization.
void main() {
  group('Data Retention Logic', () {
    List<DomainAccess> createTestData() {
      final now = DateTime.now();
      return [
        // Today
        DomainAccess(domain: 'today.com', timestamp: now, userId: 'u1'),
        // 5 days ago
        DomainAccess(
          domain: 'recent.com',
          timestamp: now.subtract(const Duration(days: 5)),
          userId: 'u1',
        ),
        // 15 days ago
        DomainAccess(
          domain: 'twoweeks.com',
          timestamp: now.subtract(const Duration(days: 15)),
          userId: 'u1',
        ),
        // 31 days ago
        DomainAccess(
          domain: 'month.com',
          timestamp: now.subtract(const Duration(days: 31)),
          userId: 'u1',
        ),
        // 60 days ago
        DomainAccess(
          domain: 'twomonths.com',
          timestamp: now.subtract(const Duration(days: 60)),
          userId: 'u1',
        ),
        // 91 days ago
        DomainAccess(
          domain: 'threemonths.com',
          timestamp: now.subtract(const Duration(days: 91)),
          userId: 'u1',
        ),
      ];
    }

    List<DomainAccess> filterByRetention(
      List<DomainAccess> data,
      int retentionDays,
    ) {
      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      return data.where((a) => a.timestamp.isAfter(cutoff)).toList();
    }

    List<DomainAccess> getExpired(List<DomainAccess> data, int retentionDays) {
      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      return data.where((a) => a.timestamp.isBefore(cutoff)).toList();
    }

    test('7-day retention keeps only last 7 days', () {
      final data = createTestData();
      final kept = filterByRetention(data, 7);
      final expired = getExpired(data, 7);

      expect(kept.length, 2); // today + 5 days ago
      expect(expired.length, 4); // 15, 31, 60, 91 days ago
      expect(
        kept.map((a) => a.domain),
        containsAll(['today.com', 'recent.com']),
      );
    });

    test('30-day retention keeps last 30 days', () {
      final data = createTestData();
      final kept = filterByRetention(data, 30);
      final expired = getExpired(data, 30);

      expect(kept.length, 3); // today, 5d, 15d
      expect(expired.length, 3); // 31d, 60d, 91d
    });

    test('90-day retention keeps most data', () {
      final data = createTestData();
      final kept = filterByRetention(data, 90);
      final expired = getExpired(data, 90);

      expect(kept.length, 5); // everything except 91 days
      expect(expired.length, 1); // 91 days ago
      expect(expired.first.domain, 'threemonths.com');
    });

    test('365-day retention keeps all data', () {
      final data = createTestData();
      final kept = filterByRetention(data, 365);

      expect(kept.length, 6); // all data within a year
    });

    test('1-day retention deletes almost everything', () {
      final data = createTestData();
      final kept = filterByRetention(data, 1);

      expect(kept.length, 1); // only today
      expect(kept.first.domain, 'today.com');
    });

    test('empty data produces no expired items', () {
      final expired = getExpired([], 30);
      expect(expired, isEmpty);
    });
  });

  group('Sync Flag Logic', () {
    test('new records are unsynced by default', () {
      final access = DomainAccess(
        domain: 'test.com',
        timestamp: DateTime.now(),
        userId: 'u1',
      );

      expect(access.synced, false);
    });

    test('can mark record as synced', () {
      final access = DomainAccess(
        domain: 'test.com',
        timestamp: DateTime.now(),
        userId: 'u1',
      );

      access.synced = true;
      expect(access.synced, true);
    });

    test('filter unsynced records', () {
      final records = [
        DomainAccess(domain: 'a.com', timestamp: DateTime.now(), userId: 'u1'),
        DomainAccess(
          domain: 'b.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          synced: true,
        ),
        DomainAccess(domain: 'c.com', timestamp: DateTime.now(), userId: 'u1'),
      ];

      final unsynced = records.where((r) => !r.synced).toList();
      expect(unsynced.length, 2);
      expect(unsynced.map((r) => r.domain), containsAll(['a.com', 'c.com']));
    });
  });
}
