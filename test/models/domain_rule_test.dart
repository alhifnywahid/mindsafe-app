import 'package:flutter_test/flutter_test.dart';
import 'package:mindsafe_flutter/data/models/domain_rule.dart';

void main() {
  group('DomainRule', () {
    test('creates with required fields', () {
      final rule = DomainRule(
        id: '1',
        pattern: 'example.com',
        category: 'safe',
      );

      expect(rule.id, '1');
      expect(rule.pattern, 'example.com');
      expect(rule.category, 'safe');
      expect(rule.priority, 0); // default
      expect(rule.isActive, true); // default
      expect(rule.isRegex, false); // default
    });

    test('creates with all fields', () {
      final rule = DomainRule(
        id: 'r2',
        pattern: r'.*\.adult\..*',
        category: 'adult',
        priority: 99,
        isActive: false,
        isRegex: true,
      );

      expect(rule.id, 'r2');
      expect(rule.pattern, r'.*\.adult\..*');
      expect(rule.category, 'adult');
      expect(rule.priority, 99);
      expect(rule.isActive, false);
      expect(rule.isRegex, true);
    });

    test('toMap produces complete output', () {
      final rule = DomainRule(
        id: 'map_test',
        pattern: 'news.com',
        category: 'safe',
        priority: 5,
        isActive: true,
        isRegex: false,
      );

      final map = rule.toMap();

      expect(map['id'], 'map_test');
      expect(map['pattern'], 'news.com');
      expect(map['category'], 'safe');
      expect(map['priority'], 5);
      expect(map['isActive'], true);
      expect(map['isRegex'], false);
    });

    test('fromMap creates correct instance', () {
      final map = {
        'id': 'from_map',
        'pattern': 'facebook.com',
        'category': 'mixed',
        'priority': 10,
        'isActive': true,
        'isRegex': false,
      };

      final rule = DomainRule.fromMap(map);

      expect(rule.id, 'from_map');
      expect(rule.pattern, 'facebook.com');
      expect(rule.category, 'mixed');
      expect(rule.priority, 10);
      expect(rule.isActive, true);
      expect(rule.isRegex, false);
    });

    test('fromMap provides defaults for missing optional fields', () {
      final map = {
        'id': 'minimal',
        'pattern': 'test.org',
        'category': 'unknown',
      };

      final rule = DomainRule.fromMap(map);

      expect(rule.priority, 0);
      expect(rule.isActive, true);
      expect(rule.isRegex, false);
    });

    test('fromMap handles completely empty map', () {
      final rule = DomainRule.fromMap({});

      expect(rule.id, '');
      expect(rule.pattern, '');
      expect(rule.category, 'unknown');
      expect(rule.priority, 0);
      expect(rule.isActive, true);
      expect(rule.isRegex, false);
    });

    test('toMap and fromMap roundtrip', () {
      final original = DomainRule(
        id: 'roundtrip',
        pattern: r'^adult.*',
        category: 'adult',
        priority: 50,
        isActive: true,
        isRegex: true,
      );

      final reconstructed = DomainRule.fromMap(original.toMap());

      expect(reconstructed.id, original.id);
      expect(reconstructed.pattern, original.pattern);
      expect(reconstructed.category, original.category);
      expect(reconstructed.priority, original.priority);
      expect(reconstructed.isActive, original.isActive);
      expect(reconstructed.isRegex, original.isRegex);
    });

    test('supports all valid categories', () {
      for (final cat in ['adult', 'mixed', 'safe', 'unknown']) {
        final rule = DomainRule(id: cat, pattern: '$cat.com', category: cat);
        expect(rule.category, cat);
      }
    });
  });
}
