import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lifter/config/auth_config.dart';
import 'package:flutter_lifter/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('guest factory creates deterministic guest user', () {
      final guest = AppUser.guest();

      expect(guest.uid, 'guest');
      expect(guest.isGuest, isTrue);
      expect(guest.authProvider, AuthProvider.guest);
      expect(guest.email, isNull);
      expect(guest.displayName, isNull);
      expect(guest.photoURL, isNull);
    });

    test('isGuest is false for non-guest providers', () {
      final user = AppUser(
        uid: 'abc123',
        email: 'test@example.com',
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
      );

      expect(user.isGuest, isFalse);
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime(2026, 2, 16, 12, 0, 0);
      final user = AppUser(
        uid: 'firebase-uid',
        email: 'alice@example.com',
        displayName: 'Alice',
        photoURL: 'https://example.com/photo.jpg',
        authProvider: AuthProvider.google,
        createdAt: now,
      );

      final json = user.toJson();
      final restored = AppUser.fromJson(json);

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.photoURL, user.photoURL);
      expect(restored.authProvider, user.authProvider);
      expect(restored.createdAt, user.createdAt);
    });

    test('copyWith creates copy with updated fields', () {
      final user = AppUser(
        uid: 'uid1',
        email: 'old@example.com',
        authProvider: AuthProvider.email,
        createdAt: DateTime(2026),
      );

      final updated = user.copyWith(email: 'new@example.com');

      expect(updated.uid, 'uid1');
      expect(updated.email, 'new@example.com');
      expect(updated.authProvider, AuthProvider.email);
    });

    test('equality is based on uid', () {
      final a = AppUser(
        uid: 'same',
        email: 'a@example.com',
        authProvider: AuthProvider.email,
        createdAt: DateTime(2026),
      );
      final b = AppUser(
        uid: 'same',
        email: 'b@example.com',
        authProvider: AuthProvider.google,
        createdAt: DateTime(2025),
      );
      final c = AppUser(
        uid: 'different',
        email: 'a@example.com',
        authProvider: AuthProvider.email,
        createdAt: DateTime(2026),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('AuthResult error message mapping', () {
    test('all enum values have names', () {
      for (final result in AuthResult.values) {
        expect(result.name, isNotEmpty);
      }
    });
  });

  group('AuthState', () {
    test('contains expected values', () {
      expect(
        AuthState.values,
        containsAll([
          AuthState.unknown,
          AuthState.authenticated,
          AuthState.unauthenticated,
          AuthState.loading,
        ]),
      );
    });
  });
}
