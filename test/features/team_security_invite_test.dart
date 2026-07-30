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

  group('Team Security & Invite Code Tests', () {
    testWidgets('Joining team by 6-digit Invite Code secures privacy and syncs team', (WidgetTester tester) async {
      final mockUser = app_user.User(
        id: 'user-remote',
        email: 'remote@example.com',
        role: 'remote',
        teamId: null,
        createdAt: DateTime.now(),
      );

      final targetTeam = Team(
        id: '3f8a91b2-1234-5678-90ab-cdef12345678',
        name: 'NorthPark Team',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);
      when(() => mockTeamService.joinTeamByInviteCodeOrName('3F8A91')).thenAnswer((_) async => targetTeam);
      when(() => mockTeamService.updateUserTeam('user-remote', targetTeam.id)).thenAnswer((_) async {});

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

      // Ensure NO public team list (e.g. northpark) is exposed on screen
      expect(find.text('northpark'), findsNothing);

      // Tap Switch Team
      await tester.tap(find.text('切换团队'));
      await tester.pumpAndSettle();

      // Enter 6-digit invite code "3F8A91"
      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, '3F8A91');
      await tester.pumpAndSettle();

      // Tap Verify & Join
      await tester.tap(find.text('验证并加入'));
      await tester.pumpAndSettle();

      // Verify joinTeamByInviteCodeOrName was invoked with 3F8A91
      verify(() => mockTeamService.joinTeamByInviteCodeOrName('3F8A91')).called(1);
      verify(() => mockTeamService.updateUserTeam('user-remote', targetTeam.id)).called(1);
    });
  });
}
