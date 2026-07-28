import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/booth/services/booth_service.dart';
import 'package:exhibition_buyer_app/features/booth/models/booth.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
import 'booth_service_test.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late BoothService boothService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    boothService = BoothService(mockSupabase);
  });

  group('BoothService单元测试', () {
    const testEventId = 'event-123';
    const testTeamId = 'team-456';
    const testUserId = 'user-789';
    const testBoothId = 'booth-001';
    const testBoothNumber = 'B01';

    final testBoothJson = {
      'id': testBoothId,
      'booth_number': testBoothNumber,
      'event_id': testEventId,
      'team_id': testTeamId,
      'created_by': testUserId,
      'created_at': '2026-07-22T10:00:00Z',
    };

    group('创建摊位', () {
      test('创建新摊位成功', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => testBoothJson);

        final booth = await boothService.createBooth(
          boothNumber: testBoothNumber,
          eventId: testEventId,
          teamId: testTeamId,
          createdBy: testUserId,
        );

        expect(booth.id, testBoothId);
        expect(booth.boothNumber, testBoothNumber);
        expect(booth.eventId, testEventId);
        expect(booth.teamId, testTeamId);
        expect(booth.createdBy, testUserId);

        verify(mockSupabase.from('booths')).called(1);
        verify(mockQueryBuilder.insert({
          'booth_number': testBoothNumber,
          'event_id': testEventId,
          'team_id': testTeamId,
          'created_by': testUserId,
        })).called(1);
      });

      test('验证摊位号在同一场次内唯一', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          ),
        );

        expect(
          () => boothService.createBooth(
            boothNumber: testBoothNumber,
            eventId: testEventId,
            teamId: testTeamId,
            createdBy: testUserId,
          ),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('获取摊位列表', () {
      test('按场次和团队获取摊位（数据隔离）', () async {
        final boothList = [
          testBoothJson,
          {
            'id': 'booth-002',
            'booth_number': 'B02',
            'event_id': testEventId,
            'team_id': testTeamId,
            'created_by': testUserId,
            'created_at': '2026-07-22T09:00:00Z',
          },
        ];

        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('event_id', testEventId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('team_id', testTeamId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false))
            .thenAnswer((_) async => boothList);

        final booths = await boothService.getBooths(
          eventId: testEventId,
          teamId: testTeamId,
        );

        expect(booths.length, 2);
        expect(booths[0].boothNumber, 'B01');
        expect(booths[1].boothNumber, 'B02');
        expect(booths.every((b) => b.eventId == testEventId), isTrue);
        expect(booths.every((b) => b.teamId == testTeamId), isTrue);

        verify(mockFilterBuilder.eq('event_id', testEventId)).called(1);
        verify(mockFilterBuilder.eq('team_id', testTeamId)).called(1);
      });

      test('按团队获取所有摊位（跨场次）', () async {
        final boothList = [
          testBoothJson,
          {
            'id': 'booth-003',
            'booth_number': 'B01',
            'event_id': 'event-456',
            'team_id': testTeamId,
            'created_by': testUserId,
            'created_at': '2026-07-21T10:00:00Z',
          },
        ];

        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('team_id', testTeamId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false))
            .thenAnswer((_) async => boothList);

        final booths = await boothService.getBoothsByTeam(testTeamId);

        expect(booths.length, 2);
        expect(booths[0].eventId, testEventId);
        expect(booths[1].eventId, 'event-456');
        expect(booths[0].boothNumber, testBoothNumber);
        expect(booths[1].boothNumber, testBoothNumber);
        expect(booths.every((b) => b.teamId == testTeamId), isTrue);
      });

      test('场次没有摊位时返回空列表', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('event_id', testEventId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('team_id', testTeamId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false))
            .thenAnswer((_) async => []);

        final booths = await boothService.getBooths(
          eventId: testEventId,
          teamId: testTeamId,
        );

        expect(booths, isEmpty);
      });
    });

    group('摊位号唯一性检查', () {
      test('检查摊位号已存在（同一场次）', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('event_id', testEventId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('booth_number', testBoothNumber))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => testBoothJson);

        final exists = await boothService.boothNumberExists(
          eventId: testEventId,
          boothNumber: testBoothNumber,
        );

        expect(exists, isTrue);
      });

      test('检查摊位号不存在', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('event_id', testEventId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('booth_number', 'B99'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        final exists = await boothService.boothNumberExists(
          eventId: testEventId,
          boothNumber: 'B99',
        );

        expect(exists, isFalse);
      });

      test('不同场次可以有相同摊位号', () async {
        const event1 = 'event-aaa';
        const event2 = 'event-bbb';

        // 在场次1创建B01
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'booth-001',
              'booth_number': testBoothNumber,
              'event_id': event1,
              'team_id': testTeamId,
              'created_by': testUserId,
              'created_at': '2026-07-22T10:00:00Z',
            });

        final booth1 = await boothService.createBooth(
          boothNumber: testBoothNumber,
          eventId: event1,
          teamId: testTeamId,
          createdBy: testUserId,
        );

        expect(booth1.boothNumber, testBoothNumber);
        expect(booth1.eventId, event1);

        // 在场次2创建B01
        when(mockFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'booth-002',
              'booth_number': testBoothNumber,
              'event_id': event2,
              'team_id': testTeamId,
              'created_by': testUserId,
              'created_at': '2026-07-22T11:00:00Z',
            });

        final booth2 = await boothService.createBooth(
          boothNumber: testBoothNumber,
          eventId: event2,
          teamId: testTeamId,
          createdBy: testUserId,
        );

        expect(booth2.boothNumber, testBoothNumber);
        expect(booth2.eventId, event2);
        expect(booth1.eventId, isNot(booth2.eventId));
      });
    });

    group('更新摊位', () {
      test('更新摊位号', () async {
        final updatedJson = {
          ...testBoothJson,
          'booth_number': 'B99',
        };

        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', testBoothId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => updatedJson);

        final booth = await boothService.updateBooth(
          boothId: testBoothId,
          boothNumber: 'B99',
        );

        expect(booth.boothNumber, 'B99');
        expect(booth.id, testBoothId);

        verify(mockQueryBuilder.update({'booth_number': 'B99'})).called(1);
      });
    });

    group('删除摊位', () {
      test('删除指定摊位', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', testBoothId))
            .thenAnswer((_) async => null);

        await boothService.deleteBooth(testBoothId);

        verify(mockSupabase.from('booths')).called(1);
        verify(mockQueryBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('id', testBoothId)).called(1);
      });
    });

    group('获取单个摊位', () {
      test('根据ID获取摊位详情', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', testBoothId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => testBoothJson);

        final booth = await boothService.getBooth(testBoothId);

        expect(booth.id, testBoothId);
        expect(booth.boothNumber, testBoothNumber);
        expect(booth.eventId, testEventId);
        expect(booth.teamId, testTeamId);
      });

      test('摊位不存在时抛出异常', () async {
        when(mockSupabase.from('booths')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 'invalid-id'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          PostgrestException(message: 'No rows found', code: 'PGRST116'),
        );

        expect(
          () => boothService.getBooth('invalid-id'),
          throwsA(isA<PostgrestException>()),
        );
      });
    });
  });
}
