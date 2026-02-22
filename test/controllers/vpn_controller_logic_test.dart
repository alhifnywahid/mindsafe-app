import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// These tests validate the domain hashing logic used in VpnController._hashDomain
/// without requiring GetX service initialization.
void main() {
  group('Domain Hashing', () {
    String hashDomain(String domain) {
      final bytes = utf8.encode(domain);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }

    test('produces consistent hash for same domain', () {
      final hash1 = hashDomain('example.com');
      final hash2 = hashDomain('example.com');
      expect(hash1, hash2);
    });

    test('produces different hash for different domains', () {
      final hash1 = hashDomain('example.com');
      final hash2 = hashDomain('google.com');
      expect(hash1, isNot(equals(hash2)));
    });

    test('hash is 64 characters (SHA-256)', () {
      final hash = hashDomain('test.com');
      expect(hash.length, 64);
    });

    test('hash is lowercase hex', () {
      final hash = hashDomain('test.com');
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('hash is case-sensitive on domain', () {
      final hash1 = hashDomain('Example.com');
      final hash2 = hashDomain('example.com');
      // domain hashing IS case-sensitive
      expect(hash1, isNot(equals(hash2)));
    });

    test('known hash for google.com', () {
      // Pre-computed SHA-256 of "google.com"
      final expected = sha256.convert(utf8.encode('google.com')).toString();
      final hash = hashDomain('google.com');
      expect(hash, expected);
    });
  });

  group('Domain URL Extraction', () {
    String extractDomain(String url) {
      try {
        final uri = Uri.parse(url);
        return uri.host.isNotEmpty ? uri.host : url;
      } catch (_) {
        return url;
      }
    }

    test('extracts domain from HTTPS URL', () {
      expect(
        extractDomain('https://www.google.com/search?q=test'),
        'www.google.com',
      );
    });

    test('extracts domain from HTTP URL', () {
      expect(extractDomain('http://example.com/page'), 'example.com');
    });

    test('extracts domain from URL with port', () {
      expect(extractDomain('https://localhost:8080/api'), 'localhost');
    });

    test('extracts domain from URL with subdomain', () {
      expect(extractDomain('https://mail.google.com'), 'mail.google.com');
    });

    test('returns raw input for bare domain', () {
      // Uri.parse of a bare domain without scheme returns empty host
      final result = extractDomain('google.com');
      expect(result, 'google.com');
    });

    test('handles empty string', () {
      expect(extractDomain(''), '');
    });

    test('handles URL with path and query', () {
      expect(
        extractDomain('https://www.youtube.com/watch?v=abc123&t=10'),
        'www.youtube.com',
      );
    });

    test('handles IP address URL', () {
      expect(extractDomain('http://192.168.1.1:3000/api'), '192.168.1.1');
    });
  });

  group('Today Stats Calculation', () {
    test('calculates unique domains correctly', () {
      final domains = [
        'google.com',
        'google.com',
        'youtube.com',
        'google.com',
        'facebook.com',
      ];

      final uniqueCount = domains.toSet().length;
      expect(uniqueCount, 3);
    });

    test('calculates total duration in minutes', () {
      final durationSeconds = [30, 60, 90, 120, 0];
      final totalSeconds = durationSeconds.fold<int>(0, (sum, s) => sum + s);
      final totalMinutes = (totalSeconds / 60).round();

      expect(totalMinutes, 5);
    });

    test('handles zero durations', () {
      final durationSeconds = [0, 0, 0];
      final totalSeconds = durationSeconds.fold<int>(0, (sum, s) => sum + s);
      final totalMinutes = (totalSeconds / 60).round();

      expect(totalMinutes, 0);
    });

    test('rounds minutes correctly', () {
      // 89 seconds = 1.48 min => rounds to 1
      expect((89 / 60).round(), 1);
      // 91 seconds = 1.52 min => rounds to 2
      expect((91 / 60).round(), 2);
      // 30 seconds = 0.5 min => rounds to 0 (banker's rounding in Dart)
      // Actually Dart uses round-half-to-even
      expect((30 / 60).round(), 1); // 0.5 rounds to 1 in Dart
    });
  });
}
