import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/team/services/team_service.dart';
import 'package:exhibition_buyer_app/features/auth/models/team.dart';
import 'package:exhibition_buyer_app/features/auth/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestTransformBuilder<T> extends Mock implements PostgrestTransformBuilder<T> {}

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
    test('createTeam 成功创建小组', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('teams')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.insert(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'team-123',
        'name': '小组A',
        'created_at': now.toIso8601String(),
      });

      final result = await teamService.createTeam(name: '小组A');

      expect(result.id, 'team-123');
      expect(result.name, '小组A');
      verify(() => mockFilterBuilder.insert({'name': '小组A'})).called(1);
    });

    test('getTeam 成功获取小组信息', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('teams')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'team-123',
        'name': '小组A',
        'created_at': now.toIso8601String(),
      });

      final result = await teamService.getTeam('team-123');

      expect(result.id, 'team-123');
      expect(result.name, '小组A');
      verify(() => mockFilterBuilder.eq('id', 'team-123')).called(1);
    });

    test('getTeam 小组不存在时返回null', () async {
      when(() => mockSupabase.from('teams')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.maybeSingle()).thenAnswer((_) async => null);

      final result = await teamService.getTeam('non-existent');

      expect(result, isNull);
    });

    test('updateTeam 成功更新小组信息', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('teams')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.update(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
      when(() => mockTransformBuilder.single()).thenAnswer((_) async => {
        'id': 'team-123',
        'name': '小组A更新',
        'created_at': now.toIso8601String(),
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

  group('TeamService - 成员管理', () {
    test('addMember 成功添加成员到小组', () async {
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.update(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);

      await teamService.addMember(userId: 'user-123', teamId: 'team-456');

      verify(() => mockFilterBuilder.update({'team_id': 'team-456'})).called(1);
      verify(() => mockFilterBuilder.eq('id', 'user-123')).called(1);
    });

    test('removeMember 成功从小组移除成员', () async {
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.update(any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);

      await teamService.removeMember(userId: 'user-123');

      verify(() => mockFilterBuilder.update({'team_id': null})).called(1);
      verify(() => mockFilterBuilder.eq('id', 'user-123')).called(1);
    });

    test('getTeamMembers 成功获取小组所有成员', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order(any(), ascending: any(named: 'ascending')))
          .thenReturn(mockFilterBuilder);
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
          'last_seen': now.subtract(Duration(minutes: 10)).toIso8601String(),
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
      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order(any(), ascending: any(named: 'ascending')))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.then(any())).thenAnswer((_) async => []);

      final result = await teamService.getTeamMembers('empty-team');

      expect(result, isEmpty);
    });
  });

  group('TeamService - 数据隔离验证', () {
    test('getTeamMembers 只返回指定小组的成员', () async {
      final now = DateTime.now();

      when(() => mockSupabase.from('users')).thenReturn(mockFilterBuilder as dynamic);
      when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.order(any(), ascending: any(named: 'ascending')))
          .thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.then(any())).thenAnswer((_) async => [
        {
          'id': 'user-1',
          'email': 'buyer1@example.com',
          'role': 'buyer',
          'team_id': 'team-A',
          'daily_color': 'green',
          'created_at': now.toIso8601String(),
        },
      ]);

      final result = await teamService.getTeamMembers('team-A');

      expect(result.length, 1);
      expect(result[0].teamId, 'team-A');
      // 验证查询条件包含team_id过滤
      verify(() => mockFilterBuilder.eq('team_id', 'team-A')).called(1);
    });
  });
}
