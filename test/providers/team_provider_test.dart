import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/team/providers/team_provider.dart';
import 'package:exhibition_buyer_app/features/team/services/team_service.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';
import 'package:exhibition_buyer_app/features/auth/models/user.dart';
import 'package:exhibition_buyer_app/features/auth/models/team.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamService extends Mock implements TeamService {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockTeamService mockTeamService;
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    mockTeamService = MockTeamService();
    mockAuthService = MockAuthService();
  });

  tearDown(() {
    container.dispose();
  });

  group('TeamProvider - 小组信息', () {
    test('currentTeamProvider 返回当前用户的小组信息', () async {
      final now = DateTime.now();
      final user = User(
        id: 'user-123',
        email: 'buyer@example.com',
        role: 'buyer',
        teamId: 'team-456',
        createdAt: now,
      );
      final team = Team(
        id: 'team-456',
        name: '小组A',
        createdAt: now,
      );

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => user);
      when(() => mockTeamService.getTeam('team-456')).thenAnswer((_) async => team);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final result = await container.read(currentTeamProvider.future);

      expect(result, isNotNull);
      expect(result!.id, 'team-456');
      expect(result.name, '小组A');
      verify(() => mockAuthService.getCurrentUser()).called(1);
      verify(() => mockTeamService.getTeam('team-456')).called(1);
    });

    test('currentTeamProvider 用户无小组时返回null', () async {
      final now = DateTime.now();
      final user = User(
        id: 'user-123',
        email: 'buyer@example.com',
        role: 'buyer',
        teamId: null,
        createdAt: now,
      );

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => user);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final result = await container.read(currentTeamProvider.future);

      expect(result, isNull);
      verify(() => mockAuthService.getCurrentUser()).called(1);
      verifyNever(() => mockTeamService.getTeam(any()));
    });
  });

  group('TeamProvider - 成员列表', () {
    test('teamMembersProvider 返回小组所有成员', () async {
      final now = DateTime.now();
      final currentUser = User(
        id: 'user-1',
        email: 'buyer1@example.com',
        role: 'buyer',
        teamId: 'team-123',
        dailyColor: 'green',
        createdAt: now,
      );
      final members = [
        User(
          id: 'user-1',
          email: 'buyer1@example.com',
          role: 'buyer',
          teamId: 'team-123',
          dailyColor: 'green',
          colorAssignedDate: DateTime.now(),
          lastSeen: now.subtract(Duration(minutes: 2)),
          createdAt: now,
        ),
        User(
          id: 'user-2',
          email: 'buyer2@example.com',
          role: 'buyer',
          teamId: 'team-123',
          dailyColor: 'blue',
          colorAssignedDate: DateTime.now(),
          lastSeen: now.subtract(Duration(minutes: 10)),
          createdAt: now,
        ),
      ];

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => currentUser);
      when(() => mockTeamService.getTeamMembers('team-123')).thenAnswer((_) async => members);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final result = await container.read(teamMembersProvider.future);

      expect(result.length, 2);
      expect(result[0].dailyColor, 'green');
      expect(result[1].dailyColor, 'blue');
      verify(() => mockTeamService.getTeamMembers('team-123')).called(1);
    });

    test('teamMembersProvider 用户无小组时返回空列表', () async {
      final now = DateTime.now();
      final currentUser = User(
        id: 'user-1',
        email: 'buyer1@example.com',
        role: 'buyer',
        teamId: null,
        createdAt: now,
      );

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => currentUser);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final result = await container.read(teamMembersProvider.future);

      expect(result, isEmpty);
      verifyNever(() => mockTeamService.getTeamMembers(any()));
    });

    test('teamMembersByIdProvider 按teamId查询成员', () async {
      final now = DateTime.now();
      final members = [
        User(
          id: 'user-1',
          email: 'buyer1@example.com',
          role: 'buyer',
          teamId: 'team-456',
          dailyColor: 'yellow',
          createdAt: now,
        ),
      ];

      when(() => mockTeamService.getTeamMembers('team-456')).thenAnswer((_) async => members);

      container = ProviderContainer(
        overrides: [
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final result = await container.read(teamMembersByIdProvider('team-456').future);

      expect(result.length, 1);
      expect(result[0].teamId, 'team-456');
      verify(() => mockTeamService.getTeamMembers('team-456')).called(1);
    });
  });

  group('TeamProvider - 在线状态', () {
    test('onlineMembersProvider 只返回在线成员', () async {
      final now = DateTime.now();
      final currentUser = User(
        id: 'user-1',
        email: 'buyer1@example.com',
        role: 'buyer',
        teamId: 'team-123',
        createdAt: now,
      );
      final members = [
        User(
          id: 'user-1',
          email: 'buyer1@example.com',
          role: 'buyer',
          teamId: 'team-123',
          dailyColor: 'green',
          lastSeen: now.subtract(Duration(minutes: 2)), // 在线
          createdAt: now,
        ),
        User(
          id: 'user-2',
          email: 'buyer2@example.com',
          role: 'buyer',
          teamId: 'team-123',
          dailyColor: 'blue',
          lastSeen: now.subtract(Duration(minutes: 10)), // 离线
          createdAt: now,
        ),
        User(
          id: 'user-3',
          email: 'buyer3@example.com',
          role: 'buyer',
          teamId: 'team-123',
          dailyColor: 'red',
          lastSeen: now.subtract(Duration(minutes: 1)), // 在线
          createdAt: now,
        ),
      ];

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => currentUser);
      when(() => mockTeamService.getTeamMembers('team-123')).thenAnswer((_) async => members);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final result = await container.read(onlineMembersProvider.future);

      expect(result.length, 2);
      expect(result[0].dailyColor, 'green');
      expect(result[1].dailyColor, 'red');
      expect(result.every((user) => user.isOnline), isTrue);
    });

    test('onlineMembersCountProvider 返回在线成员数量', () async {
      final now = DateTime.now();
      final currentUser = User(
        id: 'user-1',
        email: 'buyer1@example.com',
        role: 'buyer',
        teamId: 'team-123',
        createdAt: now,
      );
      final members = [
        User(
          id: 'user-1',
          email: 'buyer1@example.com',
          role: 'buyer',
          teamId: 'team-123',
          lastSeen: now.subtract(Duration(minutes: 2)), // 在线
          createdAt: now,
        ),
        User(
          id: 'user-2',
          email: 'buyer2@example.com',
          role: 'buyer',
          teamId: 'team-123',
          lastSeen: now.subtract(Duration(minutes: 10)), // 离线
          createdAt: now,
        ),
      ];

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => currentUser);
      when(() => mockTeamService.getTeamMembers('team-123')).thenAnswer((_) async => members);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          teamServiceProvider.overrideWithValue(mockTeamService),
        ],
      );

      final count = await container.read(onlineMembersCountProvider.future);

      expect(count, 1);
    });

    test('User.isOnline 正确判断在线状态', () {
      final now = DateTime.now();

      // 2分钟前活跃 - 在线
      final onlineUser = User(
        id: 'user-1',
        email: 'buyer1@example.com',
        role: 'buyer',
        lastSeen: now.subtract(Duration(minutes: 2)),
        createdAt: now,
      );
      expect(onlineUser.isOnline, isTrue);

      // 10分钟前活跃 - 离线
      final offlineUser = User(
        id: 'user-2',
        email: 'buyer2@example.com',
        role: 'buyer',
        lastSeen: now.subtract(Duration(minutes: 10)),
        createdAt: now,
      );
      expect(offlineUser.isOnline, isFalse);

      // 从未活跃 - 离线
      final neverSeenUser = User(
        id: 'user-3',
        email: 'buyer3@example.com',
        role: 'buyer',
        lastSeen: null,
        createdAt: now,
      );
      expect(neverSeenUser.isOnline, isFalse);
    });
  });
}
