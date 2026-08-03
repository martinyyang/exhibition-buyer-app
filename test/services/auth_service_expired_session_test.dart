import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    authService = AuthService(mockSupabase);
  });

  group('AuthService - Session Recovery & Profile Robustness Isolation Tests',
      () {
    test('currentUserId returns null when no current user', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(authService.currentUserId, isNull);
    });

    test('isAuthenticated returns true when user exists', () {
      when(() => mockAuth.currentUser).thenReturn(User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ));
      expect(authService.isAuthenticated, isTrue);
    });
  });
}
