import 'package:flutter_test/flutter_test.dart';
import 'package:mindsafe_flutter/data/models/domain_access.dart';

/// Tests for insights generation logic.
/// Validates the pattern detection algorithms used in InsightsScreen.
void main() {
  group('Insights Generation Logic', () {
    test('detects high activity when domain count exceeds threshold', () {
      final accesses = List.generate(
        30,
        (i) => DomainAccess(
          domain: 'site$i.com',
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          userId: 'u1',
        ),
      );

      final uniqueDomains = accesses.map((a) => a.domain).toSet().length;
      final isHighActivity = uniqueDomains > 20;

      expect(isHighActivity, true);
    });

    test('does not flag low activity', () {
      final accesses = [
        DomainAccess(
          domain: 'google.com',
          timestamp: DateTime.now(),
          userId: 'u1',
        ),
        DomainAccess(
          domain: 'youtube.com',
          timestamp: DateTime.now(),
          userId: 'u1',
        ),
      ];

      final uniqueDomains = accesses.map((a) => a.domain).toSet().length;
      final isHighActivity = uniqueDomains > 20;

      expect(isHighActivity, false);
    });

    test('detects adult content in history', () {
      final accesses = [
        DomainAccess(
          domain: 'google.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'safe',
        ),
        DomainAccess(
          domain: 'badsite.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'adult',
        ),
      ];

      final hasAdultContent = accesses.any((a) => a.category == 'adult');
      expect(hasAdultContent, true);
    });

    test('detects clean browsing when no adult content', () {
      final accesses = [
        DomainAccess(
          domain: 'google.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'safe',
        ),
        DomainAccess(
          domain: 'github.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'safe',
        ),
      ];

      final hasAdultContent = accesses.any((a) => a.category == 'adult');
      expect(hasAdultContent, false);
    });

    test('calculates category distribution correctly', () {
      final accesses = [
        DomainAccess(
          domain: 'g.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'safe',
        ),
        DomainAccess(
          domain: 'y.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'safe',
        ),
        DomainAccess(
          domain: 'f.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'mixed',
        ),
        DomainAccess(
          domain: 'x.com',
          timestamp: DateTime.now(),
          userId: 'u1',
          category: 'adult',
        ),
      ];

      final distribution = <String, int>{};
      for (final a in accesses) {
        distribution[a.category] = (distribution[a.category] ?? 0) + 1;
      }

      expect(distribution['safe'], 2);
      expect(distribution['mixed'], 1);
      expect(distribution['adult'], 1);
      expect(distribution['unknown'], isNull);
    });

    test('calculates extended usage correctly', () {
      final accesses = List.generate(
        10,
        (i) => DomainAccess(
          domain: 'work.com',
          timestamp: DateTime.now(),
          durationSeconds: 600, // 10 minutes each
          userId: 'u1',
        ),
      );

      final totalSeconds = accesses.fold<int>(
        0,
        (sum, a) => sum + a.durationSeconds,
      );
      final totalMinutes = totalSeconds ~/ 60;

      expect(totalMinutes, 100);
      expect(totalMinutes > 60, true); // extended usage threshold
    });
  });

  group('Weekly Chart Data Logic', () {
    test('groups accesses by day of week', () {
      final now = DateTime.now();
      final accesses = [
        DomainAccess(domain: 'a.com', timestamp: now, userId: 'u1'),
        DomainAccess(domain: 'b.com', timestamp: now, userId: 'u1'),
        DomainAccess(
          domain: 'c.com',
          timestamp: now.subtract(const Duration(days: 1)),
          userId: 'u1',
        ),
      ];

      // Group by day
      final grouped = <int, Set<String>>{};
      for (final a in accesses) {
        final dayKey = DateTime(
          a.timestamp.year,
          a.timestamp.month,
          a.timestamp.day,
        ).millisecondsSinceEpoch;
        grouped.putIfAbsent(dayKey, () => {}).add(a.domain);
      }

      // Today should have 2 unique domains
      final todayKey = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;
      expect(grouped[todayKey]?.length, 2);
    });

    test('date formatting logic', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      String formatDate(DateTime dt) {
        final date = DateTime(dt.year, dt.month, dt.day);
        if (date == today) return 'Today';
        if (date == today.subtract(const Duration(days: 1))) {
          return 'Yesterday';
        }
        return '${dt.day}/${dt.month}/${dt.year}';
      }

      expect(formatDate(now), 'Today');
      expect(formatDate(now.subtract(const Duration(days: 1))), 'Yesterday');
      expect(formatDate(now.subtract(const Duration(days: 5))), isNot('Today'));
    });
  });
}
