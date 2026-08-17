import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exhibition_buyer_app/features/auth/models/user.dart'
    as app_user;
import 'package:exhibition_buyer_app/features/auth/models/team.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';
import 'package:exhibition_buyer_app/features/team/providers/team_provider.dart';
import 'package:exhibition_buyer_app/features/team/services/team_service.dart';
import 'package:exhibition_buyer_app/features/event/providers/event_provider.dart';
import 'package:exhibition_buyer_app/features/event/screens/event_selection_screen.dart';
import 'package:exhibition_buyer_app/features/presence/providers/presence_provider.dart';
import 'package:exhibition_buyer_app/features/presence/models/user_presence.dart';
import 'package:exhibition_buyer_app/features/presence/services/user_presence_service.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

class MockTeamService extends Mock implements TeamService {}

class MockTeamPresenceNotifier extends TeamPresenceNotifier {
  MockTeamPresenceNotifier()
      : super(
          MockUserPresenceService(),
          MockRealtimeService(),
          'team-1',
        ) {
    state = const AsyncValue.data([]);
  }
}

class MockUserPresenceService extends Mock implements UserPresenceService {
  @override
  RealtimeChannel subscribeToTeamPresence(
    String teamId,
    void Function(UserPresence presence, String event) onUpdate,
  ) {
    return MockRealtimeChannel();
  }
}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockRealtimeService extends Mock implements RealtimeService {
  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {
    return Future.value();
  }
}

Widget createTestableWidget(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('zh', ''),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''),
        Locale('en', ''),
      ],
      home: child,
    ),
  );
}

void main() {
  late MockAuthService mockAuthService;
  late MockTeamService mockTeamService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockTeamService = MockTeamService();
  });

  group('UX Team Experience Tests', () {
    testWidgets(
        'EventSelectionScreen displays Team Header Bar and allows direct switching',
        (WidgetTester tester) async {
      final mockUser = app_user.User(
        id: 'user-remote',
        email: 'remote@example.com',
        role: 'remote',
        teamId: 'team-1',
        createdAt: DateTime.now(),
      );

      final team1 =
          Team(id: 'team-1', name: 'Alpha Team', createdAt: DateTime.now());
      final team2 =
          Team(id: 'team-2', name: 'Buyer Team', createdAt: DateTime.now());

      when(() => mockAuthService.getCurrentUser())
          .thenAnswer((_) async => mockUser);
      when(() => mockTeamService.getTeam('team-1'))
          .thenAnswer((_) async => team1);
      when(() => mockTeamService.joinTeamByInviteCodeOrName('Buyer Team'))
          .thenAnswer((_) async => team2);

      await tester.pumpWidget(
        createTestableWidget(
          const EventSelectionScreen(),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            teamServiceProvider.overrideWithValue(mockTeamService),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(mockUser)),
            eventsProvider.overrideWith((ref) => Future.value([])),
            teamPresenceProvider('team-1')
                .overrideWith((ref) => MockTeamPresenceNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check Team Header is present on main screen
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      // Tap Switch Team directly on main screen
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      // Quick team bottom sheet should pop up with two options
      expect(find.text('创建团队'), findsOneWidget);
      expect(find.text('凭邀请码加入买手团队'), findsOneWidget);

      // Tap "Join Team" option
      await tester.tap(find.text('凭邀请码加入买手团队'));
      await tester.pumpAndSettle();

      // Now the join team dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);

      final inputFields = find.byType(TextFormField);
      expect(inputFields, findsAtLeastNWidgets(2)); // code/name + password

      // Enter team name in first field
      await tester.enterText(inputFields.first, 'Buyer Team');
      await tester.pumpAndSettle();

      // Enter password in second field
      await tester.enterText(inputFields.at(1), 'test-password');
      await tester.pumpAndSettle();

      await tester.tap(find.text('验证并加入'));
      await tester.pumpAndSettle();

      verify(() => mockTeamService.joinTeamByInviteCodeOrName('Buyer Team',
          password: 'test-password')).called(1);
    });
  });
}
