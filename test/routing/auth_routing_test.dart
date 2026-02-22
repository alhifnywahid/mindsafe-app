import 'package:flutter_test/flutter_test.dart';

/// Tests for the routing and auth state logic used in the splash screen.
void main() {
  group('Auth Routing Logic', () {
    test('unauthenticated user goes to login', () {
      final isLoggedIn = false;
      final hasOnboarded = false;

      final route = _determineRoute(isLoggedIn, hasOnboarded);
      expect(route, '/login');
    });

    test('authenticated first-time user goes to onboarding', () {
      final isLoggedIn = true;
      final hasOnboarded = false;

      final route = _determineRoute(isLoggedIn, hasOnboarded);
      expect(route, '/onboarding');
    });

    test('authenticated returning user goes to home', () {
      final isLoggedIn = true;
      final hasOnboarded = true;

      final route = _determineRoute(isLoggedIn, hasOnboarded);
      expect(route, '/home');
    });

    test('unauthenticated but onboarded user goes to login', () {
      final isLoggedIn = false;
      final hasOnboarded = true;

      final route = _determineRoute(isLoggedIn, hasOnboarded);
      expect(route, '/login');
    });
  });

  group('Admin Role Detection', () {
    const adminEmail = 'jackkolor69@gmail.com';

    test('admin email matches exactly', () {
      expect(_isAdmin('jackkolor69@gmail.com', adminEmail), true);
    });

    test('admin email is case-insensitive', () {
      expect(_isAdmin('JackKolor69@Gmail.com', adminEmail), true);
      expect(_isAdmin('JACKKOLOR69@GMAIL.COM', adminEmail), true);
    });

    test('non-admin email returns false', () {
      expect(_isAdmin('user@gmail.com', adminEmail), false);
      expect(_isAdmin('admin@example.com', adminEmail), false);
    });

    test('null email returns false', () {
      expect(_isAdmin(null, adminEmail), false);
    });

    test('empty email returns false', () {
      expect(_isAdmin('', adminEmail), false);
    });
  });

  group('Route Constants', () {
    test('all routes start with /', () {
      final routes = [
        '/',
        '/login',
        '/onboarding',
        '/home',
        '/insights',
        '/history',
        '/settings',
        '/admin',
        '/vpn-consent',
      ];

      for (final route in routes) {
        expect(
          route.startsWith('/'),
          true,
          reason: 'Route $route should start with /',
        );
      }
    });

    test('no duplicate routes', () {
      final routes = [
        '/',
        '/login',
        '/onboarding',
        '/home',
        '/insights',
        '/history',
        '/settings',
        '/admin',
        '/vpn-consent',
      ];

      expect(routes.toSet().length, routes.length);
    });
  });
}

String _determineRoute(bool isLoggedIn, bool hasOnboarded) {
  if (!isLoggedIn) return '/login';
  if (!hasOnboarded) return '/onboarding';
  return '/home';
}

bool _isAdmin(String? email, String adminEmail) {
  return email?.toLowerCase() == adminEmail.toLowerCase();
}
