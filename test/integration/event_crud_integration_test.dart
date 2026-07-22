import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:exhibition_buyer_app/features/event/services/event_service.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock类
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

void main() {
  late MockSupabaseClient mockSupabase;
  late EventService eventService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    eventService = EventService(mockSupabase);
  });

  group('场次管理CRUD集成测试', () {
    const testTeamId = 'team-123';
    const testUserId = 'user-456';

    test('完整CRUD流程：创建 -> 读取 -> 更新 -> 删除', () async {
      // 1. 创建场次
      final createUpdateBuilder = MockPostgrestFilterBuilder();
      final createInsertBuilder = MockPostgrestFilterBuilder();
      final createSelectBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(createUpdateBuilder as dynamic);
      when(() => createUpdateBuilder.update(any())).thenReturn(createUpdateBuilder);
      when(() => createUpdateBuilder.eq('team_id', testTeamId)).thenAnswer((_) async => []);

      final createdEventData = {
        'id': 'event-new',
        'name': '测试展会',
        'start_date': '2024-06-01',
        'end_date': '2024-06-05',
        'team_id': testTeamId,
        'is_active': true,
        'created_at': '2024-05-20T10:00:00Z',
      };

      when(() => mockSupabase.from('events')).thenReturn(createInsertBuilder as dynamic);
      when(() => createInsertBuilder.insert(any())).thenReturn(createSelectBuilder);
      when(() => createSelectBuilder.select()).thenReturn(createSelectBuilder);
      when(() => createSelectBuilder.single()).thenAnswer((_) async => createdEventData);

      final createdEvent = await eventService.createEvent(
        name: '测试展会',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 5),
        teamId: testTeamId,
        setAsActive: true,
      );

      expect(createdEvent.name, '测试展会');
      expect(createdEvent.isActive, true);

      // 2. 读取单个场次
      final readBuilder = MockPostgrestFilterBuilder();
      when(() => mockSupabase.from('events')).thenReturn(readBuilder as dynamic);
      when(() => readBuilder.select()).thenReturn(readBuilder);
      when(() => readBuilder.eq('id', 'event-new')).thenReturn(readBuilder);
      when(() => readBuilder.single()).thenAnswer((_) async => createdEventData);

      final readEvent = await eventService.getEvent('event-new');
      expect(readEvent.id, 'event-new');
      expect(readEvent.name, '测试展会');

      // 3. 更新场次
      final updatedEventData = {...createdEventData, 'name': '更新后的展会'};
      final updateBuilder = MockPostgrestFilterBuilder();
      final updateSelectBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(updateBuilder as dynamic);
      when(() => updateBuilder.update({'name': '更新后的展会'})).thenReturn(updateBuilder);
      when(() => updateBuilder.eq('id', 'event-new')).thenReturn(updateSelectBuilder);
      when(() => updateSelectBuilder.select()).thenReturn(updateSelectBuilder);
      when(() => updateSelectBuilder.single()).thenAnswer((_) async => updatedEventData);

      final updatedEvent = await eventService.updateEvent(
        eventId: 'event-new',
        name: '更新后的展会',
      );
      expect(updatedEvent.name, '更新后的展会');

      // 4. 删除场次
      final deleteBuilder = MockPostgrestFilterBuilder();
      when(() => mockSupabase.from('events')).thenReturn(deleteBuilder as dynamic);
      when(() => deleteBuilder.delete()).thenReturn(deleteBuilder);
      when(() => deleteBuilder.eq('id', 'event-new')).thenAnswer((_) async => []);

      await eventService.deleteEvent('event-new');
      verify(() => deleteBuilder.delete()).called(1);
    });

    test('活跃场次切换流程', () async {
      // 创建第一个活跃场次
      final event1UpdateBuilder = MockPostgrestFilterBuilder();
      final event1InsertBuilder = MockPostgrestFilterBuilder();
      final event1SelectBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(event1UpdateBuilder as dynamic);
      when(() => event1UpdateBuilder.update(any())).thenReturn(event1UpdateBuilder);
      when(() => event1UpdateBuilder.eq('team_id', testTeamId)).thenAnswer((_) async => []);

      final event1Data = {
        'id': 'event-1',
        'name': '第一个展会',
        'start_date': '2024-06-01',
        'team_id': testTeamId,
        'is_active': true,
        'created_at': '2024-05-20T10:00:00Z',
      };

      when(() => mockSupabase.from('events')).thenReturn(event1InsertBuilder as dynamic);
      when(() => event1InsertBuilder.insert(any())).thenReturn(event1SelectBuilder);
      when(() => event1SelectBuilder.select()).thenReturn(event1SelectBuilder);
      when(() => event1SelectBuilder.single()).thenAnswer((_) async => event1Data);

      final event1 = await eventService.createEvent(
        name: '第一个展会',
        startDate: DateTime(2024, 6, 1),
        teamId: testTeamId,
        setAsActive: true,
      );
      expect(event1.isActive, true);

      // 创建第二个场次（会将第一个设为非活跃）
      final event2UpdateBuilder = MockPostgrestFilterBuilder();
      final event2InsertBuilder = MockPostgrestFilterBuilder();
      final event2SelectBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(event2UpdateBuilder as dynamic);
      when(() => event2UpdateBuilder.update({'is_active': false})).thenReturn(event2UpdateBuilder);
      when(() => event2UpdateBuilder.eq('team_id', testTeamId)).thenAnswer((_) async => []);

      final event2Data = {
        'id': 'event-2',
        'name': '第二个展会',
        'start_date': '2024-07-01',
        'team_id': testTeamId,
        'is_active': true,
        'created_at': '2024-06-20T10:00:00Z',
      };

      when(() => mockSupabase.from('events')).thenReturn(event2InsertBuilder as dynamic);
      when(() => event2InsertBuilder.insert(any())).thenReturn(event2SelectBuilder);
      when(() => event2SelectBuilder.select()).thenReturn(event2SelectBuilder);
      when(() => event2SelectBuilder.single()).thenAnswer((_) async => event2Data);

      final event2 = await eventService.createEvent(
        name: '第二个展会',
        startDate: DateTime(2024, 7, 1),
        teamId: testTeamId,
        setAsActive: true,
      );
      expect(event2.isActive, true);

      // 验证将其他场次设为非活跃的调用
      verify(() => event2UpdateBuilder.update({'is_active': false})).called(1);

      // 手动切换回第一个场次
      final switchUpdateBuilder1 = MockPostgrestFilterBuilder();
      final switchUpdateBuilder2 = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(switchUpdateBuilder1 as dynamic);
      when(() => switchUpdateBuilder1.update({'is_active': false})).thenReturn(switchUpdateBuilder1);
      when(() => switchUpdateBuilder1.eq('team_id', testTeamId)).thenAnswer((_) async => []);

      when(() => mockSupabase.from('events')).thenReturn(switchUpdateBuilder2 as dynamic);
      when(() => switchUpdateBuilder2.update({'is_active': true})).thenReturn(switchUpdateBuilder2);
      when(() => switchUpdateBuilder2.eq('id', 'event-1')).thenAnswer((_) async => [event1Data]);

      await eventService.setActiveEvent('event-1', testTeamId);

      verify(() => switchUpdateBuilder1.update({'is_active': false})).called(1);
      verify(() => switchUpdateBuilder2.update({'is_active': true})).called(1);
    });

    test('数据隔离：不同小组的场次互不影响', () async {
      const team1Id = 'team-111';
      const team2Id = 'team-222';

      // Team 1 创建场次
      final team1UpdateBuilder = MockPostgrestFilterBuilder();
      final team1InsertBuilder = MockPostgrestFilterBuilder();
      final team1SelectBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(team1UpdateBuilder as dynamic);
      when(() => team1UpdateBuilder.update(any())).thenReturn(team1UpdateBuilder);
      when(() => team1UpdateBuilder.eq('team_id', team1Id)).thenAnswer((_) async => []);

      final team1EventData = {
        'id': 'team1-event',
        'name': 'Team1展会',
        'start_date': '2024-06-01',
        'team_id': team1Id,
        'is_active': true,
        'created_at': '2024-05-20T10:00:00Z',
      };

      when(() => mockSupabase.from('events')).thenReturn(team1InsertBuilder as dynamic);
      when(() => team1InsertBuilder.insert(any())).thenReturn(team1SelectBuilder);
      when(() => team1SelectBuilder.select()).thenReturn(team1SelectBuilder);
      when(() => team1SelectBuilder.single()).thenAnswer((_) async => team1EventData);

      await eventService.createEvent(
        name: 'Team1展会',
        startDate: DateTime(2024, 6, 1),
        teamId: team1Id,
      );

      // 验证只更新了team1的场次
      verify(() => team1UpdateBuilder.eq('team_id', team1Id)).called(1);

      // Team 2 创建场次
      final team2UpdateBuilder = MockPostgrestFilterBuilder();
      final team2InsertBuilder = MockPostgrestFilterBuilder();
      final team2SelectBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('events')).thenReturn(team2UpdateBuilder as dynamic);
      when(() => team2UpdateBuilder.update(any())).thenReturn(team2UpdateBuilder);
      when(() => team2UpdateBuilder.eq('team_id', team2Id)).thenAnswer((_) async => []);

      final team2EventData = {
        'id': 'team2-event',
        'name': 'Team2展会',
        'start_date': '2024-06-01',
        'team_id': team2Id,
        'is_active': true,
        'created_at': '2024-05-20T10:00:00Z',
      };

      when(() => mockSupabase.from('events')).thenReturn(team2InsertBuilder as dynamic);
      when(() => team2InsertBuilder.insert(any())).thenReturn(team2SelectBuilder);
      when(() => team2SelectBuilder.select()).thenReturn(team2SelectBuilder);
      when(() => team2SelectBuilder.single()).thenAnswer((_) async => team2EventData);

      await eventService.createEvent(
        name: 'Team2展会',
        startDate: DateTime(2024, 6, 1),
        teamId: team2Id,
      );

      // 验证只更新了team2的场次
      verify(() => team2UpdateBuilder.eq('team_id', team2Id)).called(1);

      // 验证两个team的操作互不干扰
      verifyNever(() => team1UpdateBuilder.eq('team_id', team2Id));
      verifyNever(() => team2UpdateBuilder.eq('team_id', team1Id));
    });

    test('获取场次列表按日期倒序排列', () async {
      final userBuilder = MockPostgrestFilterBuilder();
      final eventsBuilder = MockPostgrestFilterBuilder();
      final orderBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
      when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
      when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
      when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

      final eventsData = [
        {
          'id': 'event-3',
          'name': '最新展会',
          'start_date': '2024-08-01',
          'team_id': testTeamId,
          'is_active': false,
          'created_at': '2024-07-01T10:00:00Z',
        },
        {
          'id': 'event-2',
          'name': '中间展会',
          'start_date': '2024-07-01',
          'team_id': testTeamId,
          'is_active': true,
          'created_at': '2024-06-01T10:00:00Z',
        },
        {
          'id': 'event-1',
          'name': '最早展会',
          'start_date': '2024-06-01',
          'team_id': testTeamId,
          'is_active': false,
          'created_at': '2024-05-01T10:00:00Z',
        },
      ];

      when(() => mockSupabase.from('events')).thenReturn(eventsBuilder as dynamic);
      when(() => eventsBuilder.select()).thenReturn(eventsBuilder);
      when(() => eventsBuilder.eq('team_id', testTeamId)).thenReturn(orderBuilder);
      when(() => orderBuilder.order('start_date', ascending: false))
          .thenAnswer((_) async => eventsData);

      final events = await eventService.getEvents(testUserId);

      expect(events.length, 3);
      expect(events[0].startDate, DateTime(2024, 8, 1));
      expect(events[1].startDate, DateTime(2024, 7, 1));
      expect(events[2].startDate, DateTime(2024, 6, 1));
      verify(() => orderBuilder.order('start_date', ascending: false)).called(1);
    });

    test('同一小组只能有一个活跃场次', () async {
      final activeEventsBuilder = MockPostgrestFilterBuilder();

      when(() => mockSupabase.from('users')).thenReturn(activeEventsBuilder as dynamic);
      when(() => activeEventsBuilder.select('team_id')).thenReturn(activeEventsBuilder);
      when(() => activeEventsBuilder.eq('id', testUserId)).thenReturn(activeEventsBuilder);
      when(() => activeEventsBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

      when(() => mockSupabase.from('events')).thenReturn(activeEventsBuilder as dynamic);
      when(() => activeEventsBuilder.select()).thenReturn(activeEventsBuilder);
      when(() => activeEventsBuilder.eq('team_id', testTeamId)).thenReturn(activeEventsBuilder);
      when(() => activeEventsBuilder.eq('is_active', true)).thenReturn(activeEventsBuilder);
      when(() => activeEventsBuilder.maybeSingle()).thenAnswer((_) async => {
        'id': 'active-event',
        'name': '活跃展会',
        'start_date': '2024-06-01',
        'team_id': testTeamId,
        'is_active': true,
        'created_at': '2024-05-20T10:00:00Z',
      });

      final activeEvent = await eventService.getActiveEvent(testUserId);

      expect(activeEvent, isNotNull);
      expect(activeEvent!.isActive, true);
      verify(() => activeEventsBuilder.eq('is_active', true)).called(1);
    });
  });
}
