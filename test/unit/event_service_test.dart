import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/event/services/event_service.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';

// Mock类
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}

void main() {
  late MockSupabaseClient mockSupabase;
  late EventService eventService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    eventService = EventService(mockSupabase);
  });

  group('EventService单元测试', () {
    const testUserId = 'user-123';
    const testTeamId = 'team-456';
    const testEventId = 'event-789';

    final testEventData = {
      'id': testEventId,
      'name': '深圳珠宝展2024',
      'start_date': '2024-03-15',
      'end_date': '2024-03-20',
      'team_id': testTeamId,
      'is_active': true,
      'created_at': '2024-03-10T10:00:00Z',
    };

    group('创建场次', () {
      test('创建新场次并设为活跃', () async {
        // Arrange
        final updateBuilder = MockPostgrestFilterBuilder();
        final insertBuilder = MockPostgrestFilterBuilder();
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder as dynamic);
        when(() => updateBuilder.update(any())).thenReturn(updateBuilder);
        when(() => updateBuilder.eq('team_id', testTeamId)).thenAnswer((_) async => []);

        when(() => mockSupabase.from('events')).thenReturn(insertBuilder as dynamic);
        when(() => insertBuilder.insert(any())).thenReturn(selectBuilder);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => testEventData);

        // Act
        final result = await eventService.createEvent(
          name: '深圳珠宝展2024',
          startDate: DateTime(2024, 3, 15),
          endDate: DateTime(2024, 3, 20),
          teamId: testTeamId,
          setAsActive: true,
        );

        // Assert
        expect(result.name, '深圳珠宝展2024');
        expect(result.isActive, true);
        expect(result.teamId, testTeamId);
        verify(() => updateBuilder.update({'is_active': false})).called(1);
        verify(() => insertBuilder.insert(any())).called(1);
      });

      test('创建场次时将其他场次设为非活跃', () async {
        // Arrange
        final updateBuilder = MockPostgrestFilterBuilder();
        final insertBuilder = MockPostgrestFilterBuilder();
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder as dynamic);
        when(() => updateBuilder.update({'is_active': false})).thenReturn(updateBuilder);
        when(() => updateBuilder.eq('team_id', testTeamId)).thenAnswer((_) async => []);

        when(() => mockSupabase.from('events')).thenReturn(insertBuilder as dynamic);
        when(() => insertBuilder.insert(any())).thenReturn(selectBuilder);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => testEventData);

        // Act
        await eventService.createEvent(
          name: '深圳珠宝展2024',
          startDate: DateTime(2024, 3, 15),
          teamId: testTeamId,
          setAsActive: true,
        );

        // Assert
        verify(() => updateBuilder.update({'is_active': false})).called(1);
        verify(() => updateBuilder.eq('team_id', testTeamId)).called(1);
      });

      test('创建非活跃场次', () async {
        // Arrange
        final inactiveEventData = {...testEventData, 'is_active': false};
        final insertBuilder = MockPostgrestFilterBuilder();
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(insertBuilder as dynamic);
        when(() => insertBuilder.insert(any())).thenReturn(selectBuilder);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => inactiveEventData);

        // Act
        final result = await eventService.createEvent(
          name: '深圳珠宝展2024',
          startDate: DateTime(2024, 3, 15),
          teamId: testTeamId,
          setAsActive: false,
        );

        // Assert
        expect(result.isActive, false);
        verifyNever(() => mockSupabase.from('events').update(any()));
      });
    });

    group('获取场次列表', () {
      test('按用户获取所有场次', () async {
        // Arrange
        final userBuilder = MockPostgrestFilterBuilder();
        final eventsBuilder = MockPostgrestFilterBuilder();
        final orderBuilder = MockPostgrestFilterBuilder();

        final event1 = {...testEventData, 'start_date': '2024-03-15'};
        final event2 = {...testEventData, 'id': 'event-790', 'start_date': '2024-02-10'};

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

        when(() => mockSupabase.from('events')).thenReturn(eventsBuilder as dynamic);
        when(() => eventsBuilder.select()).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('team_id', testTeamId)).thenReturn(orderBuilder);
        when(() => orderBuilder.order('start_date', ascending: false))
            .thenAnswer((_) async => [event1, event2]);

        // Act
        final result = await eventService.getEvents(testUserId);

        // Assert
        expect(result.length, 2);
        expect(result[0].startDate, DateTime(2024, 3, 15));
        expect(result[1].startDate, DateTime(2024, 2, 10));
      });

      test('用户没有team_id时返回空列表', () async {
        // Arrange
        final userBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': null});

        // Act
        final result = await eventService.getEvents(testUserId);

        // Assert
        expect(result, isEmpty);
      });

      test('团队没有场次时返回空列表', () async {
        // Arrange
        final userBuilder = MockPostgrestFilterBuilder();
        final eventsBuilder = MockPostgrestFilterBuilder();
        final orderBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

        when(() => mockSupabase.from('events')).thenReturn(eventsBuilder as dynamic);
        when(() => eventsBuilder.select()).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('team_id', testTeamId)).thenReturn(orderBuilder);
        when(() => orderBuilder.order('start_date', ascending: false))
            .thenAnswer((_) async => []);

        // Act
        final result = await eventService.getEvents(testUserId);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('获取活跃场次', () {
      test('获取用户的活跃场次', () async {
        // Arrange
        final userBuilder = MockPostgrestFilterBuilder();
        final eventsBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

        when(() => mockSupabase.from('events')).thenReturn(eventsBuilder as dynamic);
        when(() => eventsBuilder.select()).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('team_id', testTeamId)).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('is_active', true)).thenReturn(eventsBuilder);
        when(() => eventsBuilder.maybeSingle()).thenAnswer((_) async => testEventData);

        // Act
        final result = await eventService.getActiveEvent(testUserId);

        // Assert
        expect(result, isNotNull);
        expect(result!.isActive, true);
        expect(result.id, testEventId);
      });

      test('没有活跃场次时返回null', () async {
        // Arrange
        final userBuilder = MockPostgrestFilterBuilder();
        final eventsBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

        when(() => mockSupabase.from('events')).thenReturn(eventsBuilder as dynamic);
        when(() => eventsBuilder.select()).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('team_id', testTeamId)).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('is_active', true)).thenReturn(eventsBuilder);
        when(() => eventsBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Act
        final result = await eventService.getActiveEvent(testUserId);

        // Assert
        expect(result, isNull);
      });

      test('用户没有team_id时返回null', () async {
        // Arrange
        final userBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': null});

        // Act
        final result = await eventService.getActiveEvent(testUserId);

        // Assert
        expect(result, isNull);
      });
    });

    group('设置活跃场次', () {
      test('切换活跃场次', () async {
        // Arrange
        final updateBuilder1 = MockPostgrestFilterBuilder();
        final updateBuilder2 = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder1 as dynamic);
        when(() => updateBuilder1.update({'is_active': false})).thenReturn(updateBuilder1);
        when(() => updateBuilder1.eq('team_id', testTeamId)).thenAnswer((_) async => []);

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder2 as dynamic);
        when(() => updateBuilder2.update({'is_active': true})).thenReturn(updateBuilder2);
        when(() => updateBuilder2.eq('id', testEventId)).thenAnswer((_) async => [testEventData]);

        // Act
        await eventService.setActiveEvent(testEventId, testTeamId);

        // Assert
        verify(() => updateBuilder1.update({'is_active': false})).called(1);
        verify(() => updateBuilder1.eq('team_id', testTeamId)).called(1);
        verify(() => updateBuilder2.update({'is_active': true})).called(1);
        verify(() => updateBuilder2.eq('id', testEventId)).called(1);
      });
    });

    group('更新场次', () {
      test('更新场次名称', () async {
        // Arrange
        final updatedData = {...testEventData, 'name': '上海珠宝展2024'};
        final updateBuilder = MockPostgrestFilterBuilder();
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder as dynamic);
        when(() => updateBuilder.update(any())).thenReturn(updateBuilder);
        when(() => updateBuilder.eq('id', testEventId)).thenReturn(selectBuilder);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => updatedData);

        // Act
        final result = await eventService.updateEvent(
          eventId: testEventId,
          name: '上海珠宝展2024',
        );

        // Assert
        expect(result.name, '上海珠宝展2024');
        verify(() => updateBuilder.update({'name': '上海珠宝展2024'})).called(1);
      });

      test('更新场次日期', () async {
        // Arrange
        final updatedData = {
          ...testEventData,
          'start_date': '2024-04-01',
          'end_date': '2024-04-05',
        };
        final updateBuilder = MockPostgrestFilterBuilder();
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder as dynamic);
        when(() => updateBuilder.update(any())).thenReturn(updateBuilder);
        when(() => updateBuilder.eq('id', testEventId)).thenReturn(selectBuilder);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => updatedData);

        // Act
        final result = await eventService.updateEvent(
          eventId: testEventId,
          startDate: DateTime(2024, 4, 1),
          endDate: DateTime(2024, 4, 5),
        );

        // Assert
        expect(result.startDate, DateTime(2024, 4, 1));
        expect(result.endDate, DateTime(2024, 4, 5));
      });

      test('部分字段更新（只更新name）', () async {
        // Arrange
        final updatedData = {...testEventData, 'name': '广州珠宝展2024'};
        final updateBuilder = MockPostgrestFilterBuilder();
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(updateBuilder as dynamic);
        when(() => updateBuilder.update({'name': '广州珠宝展2024'})).thenReturn(updateBuilder);
        when(() => updateBuilder.eq('id', testEventId)).thenReturn(selectBuilder);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => updatedData);

        // Act
        await eventService.updateEvent(
          eventId: testEventId,
          name: '广州珠宝展2024',
        );

        // Assert
        verify(() => updateBuilder.update({'name': '广州珠宝展2024'})).called(1);
        verifyNever(() => updateBuilder.update(any(that: predicate((Map<String, dynamic> data) {
          return data.containsKey('start_date') || data.containsKey('end_date');
        }))));
      });
    });

    group('删除场次', () {
      test('删除指定场次', () async {
        // Arrange
        final deleteBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(deleteBuilder as dynamic);
        when(() => deleteBuilder.delete()).thenReturn(deleteBuilder);
        when(() => deleteBuilder.eq('id', testEventId)).thenAnswer((_) async => []);

        // Act
        await eventService.deleteEvent(testEventId);

        // Assert
        verify(() => deleteBuilder.delete()).called(1);
        verify(() => deleteBuilder.eq('id', testEventId)).called(1);
      });
    });

    group('获取单个场次', () {
      test('根据ID获取场次详情', () async {
        // Arrange
        final selectBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('events')).thenReturn(selectBuilder as dynamic);
        when(() => selectBuilder.select()).thenReturn(selectBuilder);
        when(() => selectBuilder.eq('id', testEventId)).thenReturn(selectBuilder);
        when(() => selectBuilder.single()).thenAnswer((_) async => testEventData);

        // Act
        final result = await eventService.getEvent(testEventId);

        // Assert
        expect(result.id, testEventId);
        expect(result.name, '深圳珠宝展2024');
        expect(result.teamId, testTeamId);
      });
    });

    group('数据隔离', () {
      test('只能访问本小组的场次', () async {
        // Arrange
        const otherTeamId = 'team-999';
        final userBuilder = MockPostgrestFilterBuilder();
        final eventsBuilder = MockPostgrestFilterBuilder();
        final orderBuilder = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('users')).thenReturn(userBuilder as dynamic);
        when(() => userBuilder.select('team_id')).thenReturn(userBuilder);
        when(() => userBuilder.eq('id', testUserId)).thenReturn(userBuilder);
        when(() => userBuilder.single()).thenAnswer((_) async => {'team_id': testTeamId});

        when(() => mockSupabase.from('events')).thenReturn(eventsBuilder as dynamic);
        when(() => eventsBuilder.select()).thenReturn(eventsBuilder);
        when(() => eventsBuilder.eq('team_id', testTeamId)).thenReturn(orderBuilder);
        when(() => orderBuilder.order('start_date', ascending: false))
            .thenAnswer((_) async => [testEventData]);

        // Act
        final result = await eventService.getEvents(testUserId);

        // Assert
        expect(result.length, 1);
        expect(result.first.teamId, testTeamId);
        verify(() => eventsBuilder.eq('team_id', testTeamId)).called(1);
        verifyNever(() => eventsBuilder.eq('team_id', otherTeamId));
      });
    });
  });
}
