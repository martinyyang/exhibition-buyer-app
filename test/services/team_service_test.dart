import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/team/services/team_service.dart';
import 'package:exhibition_buyer_app/features/auth/models/team.dart';
import 'package:exhibition_buyer_app/features/auth/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late MockPostgrestTransformBuilder mockTransformBuilder;
  late TeamService teamService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockTransformBuilder = MockPostgrestTransformBuilder();
    teamService = TeamService(mockSupabase);
  });

  group('TeamService - 创建和获取小组', () {
    test('createTeam 通过 RPC 成功创建小组并自动加入', () async {
      final now = DateTime.now();

      when(() => mockSupabase.rpc('create_team', params: any(named: 'params')))
          .thenAnswer((_) async => {
                'id': 'team-123',
                'name': '小组A',
                'created_at': now.toIso8601String(),
                'creator_id': 'user-1',
              });

      final result = await teamService.createTeam(
        name: '小组A',
        password: 'secret',
      );

      expect(result.id, 'team-123');
      expect(result.name, '小组A');
      verify(() => mockSupabase.rpc('create_team', params: {
            'p_name': '小组A',
            'p_password': 'secret',
          })).called(1);
    });

    test('createTeam 密码为空时抛出异常', () async {
      expect(
        () => teamService.createTeam(name: '小组A', password: ''),
        throwsA(isA<Exception>()),
      );
    });

    test('getTeam 成功获取小组信息（仅非敏感列）', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('teams'))
          .thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select('id,name,created_at,creator_id'))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any()))
          .thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.maybeSingle()).thenAnswer((_) async => {
            'id': 'team-123',
            'name': '小组A',
            'created_at': now.toIso8601String(),
            'creator_id': 'user-1',
          });

      final result = await teamService.getTeam('team-123');

      expect(result?.id, 'team-123');
      expect(result?.name, '小组A');
      // 验证只查询非敏感列，绝不包含 password
      verify(() => mockFilterBuilder.select('id,name,created_at,creator_id'))
          .called(1);
    });

    test('getTeam 小组不存在时返回null', () async {
      when(() => mockSupabase.from('teams'))
          .thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select('id,name,created_at,creator_id'))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any()))
          .thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.maybeSingle())
          .thenAnswer((_) async => null);

      final result = await teamService.getTeam('non-existent');

      expect(result, isNull);
    });

    test('updateTeam 成功更新小组名称', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('teams'))
          .thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.update(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any()))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.select('id,name,created_at,creator_id'))
          .thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
            'id': 'team-123',
            'name': '小组A更新',
            'created_at': now.toIso8601String(),
            'creator_id': 'user-1',
          });

      final result = await teamService.updateTeam(
        teamId: 'team-123',
        name: '小组A更新',
      );

      expect(result.name, '小组A更新');
      verify(() => mockFilterBuilder.update({'name': '小组A更新'})).called(1);
      verify(() => mockFilterBuilder.eq('id', 'team-123')).called(1);
    });
  });

  group('TeamService - 加入团队（服务端密码验证）', () {
    test('joinTeamByIdentifierAndPassword 通过 RPC 验证密码并加入', () async {
      final now = DateTime.now();

      when(() => mockSupabase.rpc('join_team', params: any(named: 'params')))
          .thenAnswer((_) async => {
                'id': 'team-456',
                'name': '小组B',
                'created_at': now.toIso8601String(),
                'creator_id': 'user-9',
              });

      final result = await teamService.joinTeamByIdentifierAndPassword(
        identifier: '小组B',
        password: 'pwd123',
      );

      expect(result.id, 'team-456');
      expect(result.name, '小组B');
      verify(() => mockSupabase.rpc('join_team', params: {
            'p_identifier': '小组B',
            'p_password': 'pwd123',
          })).called(1);
    });

    test('joinTeamByInviteCodeOrName 转发到 RPC 并传递密码', () async {
      final now = DateTime.now();

      when(() => mockSupabase.rpc('join_team', params: any(named: 'params')))
          .thenAnswer((_) async => {
                'id': 'team-456',
                'name': '小组B',
                'created_at': now.toIso8601String(),
                'creator_id': 'user-9',
              });

      final result = await teamService.joinTeamByInviteCodeOrName(
        '3F8A91',
        password: 'test-password',
      );

      expect(result.name, '小组B');
      verify(() => mockSupabase.rpc('join_team', params: {
            'p_identifier': '3F8A91',
            'p_password': 'test-password',
          })).called(1);
    });

    test('空标识符或密码时抛出异常', () async {
      expect(
        () => teamService.joinTeamByIdentifierAndPassword(
          identifier: '  ',
          password: 'pwd',
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => teamService.joinTeamByIdentifierAndPassword(
          identifier: 'team',
          password: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('RPC 返回空时抛出团队不存在异常', () async {
      when(() => mockSupabase.rpc('join_team', params: any(named: 'params')))
          .thenAnswer((_) async => []);

      expect(
        () => teamService.joinTeamByIdentifierAndPassword(
          identifier: 'ghost',
          password: 'wrong',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TeamService - 成员管理', () {
    test('getTeamMembers 成功获取小组所有成员', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('users'))
          .thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any()))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order(any(),
          ascending: any(named: 'ascending'))).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.then(any())).thenAnswer((_) async => [
            {
              'id': 'user-1',
              'email': 'buyer1@example.com',
              'role': 'buyer',
              'team_id': 'team-123',
              'daily_color': 'green',
              'color_assigned_date': '2026-07-22',
              'last_seen': now.subtract(Duration(minutes: 2)).toIso8601String(),
              'created_at': now.toIso8601String(),
            },
            {
              'id': 'user-2',
              'email': 'buyer2@example.com',
              'role': 'buyer',
              'team_id': 'team-123',
              'daily_color': 'blue',
              'color_assigned_date': '2026-07-22',
              'last_seen':
                  now.subtract(Duration(minutes: 10)).toIso8601String(),
              'created_at': now.toIso8601String(),
            },
          ]);

      final result = await teamService.getTeamMembers('team-123');

      expect(result.length, 2);
      expect(result[0].email, 'buyer1@example.com');
      expect(result[0].dailyColor, 'green');
      expect(result[1].email, 'buyer2@example.com');
      expect(result[1].dailyColor, 'blue');
      verify(() => mockFilterBuilder.eq('team_id', 'team-123')).called(1);
    });

    test('getTeamMembers 空小组返回空列表', () async {
      when(() => mockSupabase.from('users'))
          .thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any()))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order(any(),
          ascending: any(named: 'ascending'))).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.then(any())).thenAnswer((_) async => []);

      final result = await teamService.getTeamMembers('empty-team');

      expect(result, isEmpty);
    });
  });
}
