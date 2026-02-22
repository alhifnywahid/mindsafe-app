import 'package:flutter_test/flutter_test.dart';

/// Tests for the domain classification logic used by DomainClassifier.
/// Tests the pattern-matching algorithms without requiring Hive/GetX initialization.
void main() {
  group('Domain Classification Logic', () {
    // Replicate DomainClassifier.classifyDomain logic
    String classifyDomain(String domain, List<_MockRule> rules) {
      final activeRules = rules.where((r) => r.isActive).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));

      for (var rule in activeRules) {
        if (rule.isRegex) {
          final regex = RegExp(rule.pattern);
          if (regex.hasMatch(domain)) {
            return rule.category;
          }
        } else {
          if (domain.contains(rule.pattern) ||
              domain.endsWith('.${rule.pattern}')) {
            return rule.category;
          }
        }
      }

      return 'unknown';
    }

    test('exact match classification', () {
      final rules = [
        _MockRule('google.com', 'safe', 10),
        _MockRule('youtube.com', 'mixed', 5),
      ];

      expect(classifyDomain('google.com', rules), 'safe');
      expect(classifyDomain('youtube.com', rules), 'mixed');
    });

    test('partial domain match (contains)', () {
      final rules = [_MockRule('google.com', 'safe', 10)];

      expect(classifyDomain('mail.google.com', rules), 'safe');
      expect(classifyDomain('www.google.com', rules), 'safe');
    });

    test('subdomain match (endsWith)', () {
      final rules = [_MockRule('google.com', 'safe', 10)];

      expect(classifyDomain('docs.google.com', rules), 'safe');
    });

    test('regex matching', () {
      final rules = [
        _MockRule(r'.*porn.*', 'adult', 100, isRegex: true),
        _MockRule(r'.*xxx.*', 'adult', 100, isRegex: true),
      ];

      expect(classifyDomain('pornhub.com', rules), 'adult');
      expect(classifyDomain('xxxsite.com', rules), 'adult');
      expect(classifyDomain('google.com', rules), 'unknown');
    });

    test('priority ordering', () {
      final rules = [
        _MockRule('youtube.com', 'safe', 100), // higher priority
        _MockRule('youtube.com', 'mixed', 5), // lower priority
      ];

      // Higher priority rule should win
      expect(classifyDomain('youtube.com', rules), 'safe');
    });

    test('priority ordering reversed insertion', () {
      final rules = [
        _MockRule('youtube.com', 'mixed', 5), // lower priority (first in list)
        _MockRule(
          'youtube.com',
          'safe',
          100,
        ), // higher priority (second in list)
      ];

      // Should still use higher priority rule
      expect(classifyDomain('youtube.com', rules), 'safe');
    });

    test('inactive rules are ignored', () {
      final rules = [
        _MockRule('google.com', 'adult', 100, isActive: false),
        _MockRule('google.com', 'safe', 10),
      ];

      expect(classifyDomain('google.com', rules), 'safe');
    });

    test('all inactive rules returns unknown', () {
      final rules = [_MockRule('google.com', 'safe', 10, isActive: false)];

      expect(classifyDomain('google.com', rules), 'unknown');
    });

    test('no matching rules returns unknown', () {
      final rules = [_MockRule('facebook.com', 'safe', 10)];

      expect(classifyDomain('twitter.com', rules), 'unknown');
    });

    test('empty rules list returns unknown', () {
      expect(classifyDomain('google.com', []), 'unknown');
    });

    test('regex vs exact match priority', () {
      final rules = [
        _MockRule(r'.*google.*', 'mixed', 5, isRegex: true),
        _MockRule('google.com', 'safe', 10),
      ];

      // Exact match has higher priority (10 > 5)
      expect(classifyDomain('google.com', rules), 'safe');
    });

    test('multiple regex rules checked by priority', () {
      final rules = [
        _MockRule(r'.*\.edu$', 'safe', 50, isRegex: true),
        _MockRule(r'.*adult.*', 'adult', 100, isRegex: true),
      ];

      expect(classifyDomain('mit.edu', rules), 'safe');
      expect(classifyDomain('adult-content.edu', rules), 'adult');
    });

    test('domain with special characters', () {
      final rules = [_MockRule('example.co.uk', 'safe', 10)];

      expect(classifyDomain('example.co.uk', rules), 'safe');
      expect(classifyDomain('shop.example.co.uk', rules), 'safe');
    });

    test(
      'case sensitivity - domains should match case-insensitively in practice',
      () {
        // Note: The current classifier uses contains() which is case-sensitive
        // This documents expected behavior
        final rules = [_MockRule('google.com', 'safe', 10)];

        expect(
          classifyDomain('GOOGLE.COM', rules),
          'unknown',
        ); // case-sensitive
        expect(classifyDomain('google.com', rules), 'safe');
      },
    );
  });
}

class _MockRule {
  final String pattern;
  final String category;
  final int priority;
  final bool isActive;
  final bool isRegex;

  _MockRule(
    this.pattern,
    this.category,
    this.priority, {
    this.isActive = true,
    this.isRegex = false,
  });
}
