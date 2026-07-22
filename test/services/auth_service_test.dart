import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';
import 'package:exhibition_buyer_app/features/auth/models/user.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockSupabaseUser extends Mock implements User {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}
class MockPostgrestTransformBuilder<T> extends Mock implements PostgrestTransformBuilder<T> {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late MockPostgrestTransformBuilder mockTransformBuilder;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockTransformBuilder = MockPostgrestTransformBuilder();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    authService = AuthService(mockSupabase);
  });

  group('AuthService - 基础认证功能', () {
    test('signIn 成功返回用户', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockSupabaseUser();
      final now = DateTime.now();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      // Mock数据库查询
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'user-123',
        'email': 'test@example.com',
        'role': 'remote',
        'team_id': 'team-1',
        'created_at': now.toIso8601String(),
      });

      final result = await authService.signIn('test@example.com', 'password123');

      expect(result.id, 'user-123');
      expect(result.email, 'test@example.com');
      expect(result.role, 'remote');
      verify(() => mockAuth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('signIn 失败抛出异常', () async {
      final mockResponse = MockAuthResponse();
      when(() => mockResponse.user).thenReturn(null);
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      expect(
        () => authService.signIn('test@example.com', 'wrong'),
        throwsException,
      );
    });

    test('signUp 成功创建用户', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockSupabaseUser();
      final now = DateTime.now();

      when(() => mockUser.id).thenReturn('user-456');
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      // Mock插入和查询
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.insert(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'user-456',
        'email': 'new@example.com',
        'role': 'buyer',
        'team_id': 'team-1',
        'created_at': now.toIso8601String(),
      });

      final result = await authService.signUp(
        email: 'new@example.com',
        password: 'password123',
        role: 'buyer',
        teamId: 'team-1',
      );

      expect(result.id, 'user-456');
      expect(result.email, 'new@example.com');
      expect(result.role, 'buyer');
    });

    test('signOut 成功退出', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      await authService.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('currentUserId 返回当前用户ID', () {
      final mockUser = MockSupabaseUser();
      when(() => mockUser.id).thenReturn('current-user-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final userId = authService.currentUserId;

      expect(userId, 'current-user-123');
    });

    test('currentUserId 未登录时返回null', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      final userId = authService.currentUserId;

      expect(userId, isNull);
    });

    test('isAuthenticated 已登录返回true', () {
      final mockUser = MockSupabaseUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(authService.isAuthenticated, isTrue);
    });

    test('isAuthenticated 未登录返回false', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(authService.isAuthenticated, isFalse);
    });
  });

  group('AuthService - 买手颜色标识分配', () {
    test('买手登录时自动分配每日颜色', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockSupabaseUser();
      final today = DateTime.now().toIso8601String().split('T')[0];

      when(() => mockUser.id).thenReturn('buyer-123');
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      // Mock查询买手用户（无颜色）
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockFilterBuilder.update(any())).thenReturn(mockFilterBuilder);

      var callCount = 0;
      when(() => mockTransformBuilder.single()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          // 第一次查询：无颜色
          return {
            'id': 'buyer-123',
            'email': 'buyer@example.com',
            'role': 'buyer',
            'team_id': 'team-1',
            'created_at': DateTime.now().toIso8601String(),
          };
        }
        // update后不会再调用single，所以这里不需要返回
        return {};
      });

      await authService.signIn('buyer@example.com', 'password123');

      verify(() => mockFilterBuilder.update(any())).called(1);
    });

    test('买手同一天重复登录不重新分配颜色', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockSupabaseUser();
      final today = DateTime.now().toIso8601String().split('T')[0];

      when(() => mockUser.id).thenReturn('buyer-123');
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      // Mock查询买手用户（已有今天的颜色）
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'buyer-123',
        'email': 'buyer@example.com',
        'role': 'buyer',
        'team_id': 'team-1',
        'daily_color': 'blue',
        'color_assigned_date': today,
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await authService.signIn('buyer@example.com', 'password123');

      expect(result.dailyColor, 'blue');
      expect(result.colorAssignedDate?.toIso8601String().split('T')[0], today);
      // 不应该调用update
      verifyNever(() => mockFilterBuilder.update(any()));
    });

    test('远程用户登录不分配颜色', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockSupabaseUser();

      when(() => mockUser.id).thenReturn('remote-123');
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      // Mock查询远程用户
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'remote-123',
        'email': 'remote@example.com',
        'role': 'remote',
        'team_id': 'team-1',
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await authService.signIn('remote@example.com', 'password123');

      expect(result.isRemote, isTrue);
      expect(result.dailyColor, isNull);
      // 不应该调用update
      verifyNever(() => mockFilterBuilder.update(any()));
    });

    test('getCurrentUser 为买手自动检查并分配每日颜色', () async {
      final mockUser = MockSupabaseUser();
      final today = DateTime.now().toIso8601String().split('T')[0];

      when(() => mockUser.id).thenReturn('buyer-123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockFilterBuilder.update(any())).thenReturn(mockFilterBuilder);

      var maybeSingleCallCount = 0;
      when(() => mockTransformBuilder.maybeSingle()).thenAnswer((_) async {
        maybeSingleCallCount++;
        // 第一次：无颜色
        return {
          'id': 'buyer-123',
          'email': 'buyer@example.com',
          'role': 'buyer',
          'team_id': 'team-1',
          'created_at': DateTime.now().toIso8601String(),
        };
      });

      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'buyer-123',
        'email': 'buyer@example.com',
        'role': 'buyer',
        'team_id': 'team-1',
        'daily_color': 'red',
        'color_assigned_date': today,
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await authService.getCurrentUser();

      expect(result, isNotNull);
      expect(result!.dailyColor, 'red');
      verify(() => mockFilterBuilder.update(any())).called(1);
    });

    test('分配的颜色在允许的范围内', () async {
      final mockResponse = MockAuthResponse();
      final mockUser = MockSupabaseUser();
      final today = DateTime.now().toIso8601String().split('T')[0];

      when(() => mockUser.id).thenReturn('buyer-123');
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockResponse);

      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);

      String? assignedColor;
      when(() => mockFilterBuilder.update(any())).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        assignedColor = data['daily_color'] as String;
        return mockFilterBuilder;
      });

      when(() => mockTransformBuilder.single()).thenAnswer((_) async {
        return {
          'id': 'buyer-123',
          'email': 'buyer@example.com',
          'role': 'buyer',
          'team_id': 'team-1',
          'created_at': DateTime.now().toIso8601String(),
        };
      });

      await authService.signIn('buyer@example.com', 'password123');

      expect(assignedColor, isNotNull);
      expect(
        ['green', 'blue', 'yellow', 'red', 'purple', 'orange'],
        contains(assignedColor),
      );
    });
  });
}
