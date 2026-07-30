import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exhibition_buyer_app/features/auth/models/user.dart' as app_user;
import 'package:exhibition_buyer_app/features/auth/models/team.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';
import 'package:exhibition_buyer_app/features/team/providers/team_provider.dart';
import 'package:exhibition_buyer_app/features/team/services/team_service.dart';
import 'package:exhibition_buyer_app/features/event/providers/event_provider.dart';
import 'package:exhibition_buyer_app/features/event/screens/event_selection_screen.dart';

class MockAuthService extends Mock implements AuthService {}
class MockTeamService extends Mock implements TeamService {}

Widget createTestableWidget(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
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
    testWidgets('EventSelectionScreen displays Team Header Bar and allows direct switching', (WidgetTester tester) async {
      final mockUser = app_user.User(
        id: 'user-remote',
        email: 'remote@example.com',
        role: 'remote',
        teamId: 'team-1',
        createdAt: DateTime.now(),
      );

      final team1 = Team(id: 'team-1', name: 'Alpha Team', createdAt: DateTime.now());
      final team2 = Team(id: 'team-2', name: 'Buyer Team', createdAt: DateTime.now());

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);
      when(() => mockTeamService.getTeam('team-1')).thenAnswer((_) async => team1);
      when(() => mockTeamService.getAllTeams()).thenAnswer((_) async => [team1, team2]);

      await tester.pumpWidget(
        createTestableWidget(
          const EventSelectionScreen(),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            teamServiceProvider.overrideWithValue(mockTeamService),
            currentUserDataProvider.overrideWith((ref) => Future.value(mockUser)),
            eventsProvider.overrideWith((ref) => Future.value([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check Team Header is present on main screen
      expect(find.textContaining('当前团队:'), findsOneWidget);
      expect(find.text('切换团队'), findsOneWidget);

      // Check smart empty state button
      expect(find.text('一键匹配 / 加入现场团队'), findsOneWidget);

      // Tap Switch Team directly on main screen
      await tester.tap(find.text('切换团队'));
      await tester.pumpAndSettle();

      // Quick team dialog should pop up immediately without going to Settings
      expect(find.text('一键加入现场买手团队'), findsOneWidget);
      expect(find.text('Buyer Team'), findsOneWidget);
    });
  });
}
