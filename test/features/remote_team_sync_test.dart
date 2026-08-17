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
import 'package:exhibition_buyer_app/features/settings/screens/settings_screen.dart';

class MockAuthService extends Mock implements AuthService {}

class MockTeamService extends Mock implements TeamService {}

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

  group('Remote Team Sync & GetOrCreate Team Tests', () {
    testWidgets(
        'Joining existing team in SettingsScreen updates team and invalidates providers',
        (WidgetTester tester) async {
      final mockUser = app_user.User(
        id: 'user-remote',
        email: 'remote@example.com',
        role: 'remote',
        teamId: 'team-old',
        createdAt: DateTime.now(),
      );

      final oldTeam = Team(
        id: 'team-old',
        name: 'Old Team',
        createdAt: DateTime.now(),
      );

      final sharedTeam = Team(
        id: 'team-shared-123',
        name: 'Apple Team',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthService.getCurrentUser())
          .thenAnswer((_) async => mockUser);
      when(() => mockTeamService.getTeam('team-old'))
          .thenAnswer((_) async => oldTeam);
      when(() => mockTeamService.joinTeamByInviteCodeOrName('Apple Team'))
          .thenAnswer((_) async => sharedTeam);

      await tester.pumpWidget(
        createTestableWidget(
          const SettingsScreen(),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            teamServiceProvider.overrideWithValue(mockTeamService),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(mockUser)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Edit icon to change team
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Enter "Apple Team" and password
      final inputFields = find.byType(TextFormField);
      await tester.enterText(inputFields.first, 'Apple Team');
      await tester.pumpAndSettle();
      await tester.enterText(inputFields.at(1), 'test-password');
      await tester.pumpAndSettle();

      // Click Save
      await tester.tap(find.text('验证并加入'));
      await tester.pumpAndSettle();

      // Verify joinTeamByInviteCodeOrName was called with password
      verify(() => mockTeamService.joinTeamByInviteCodeOrName('Apple Team',
          password: 'test-password')).called(1);
    });
  });
}
