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
import 'package:exhibition_buyer_app/features/settings/screens/settings_screen.dart';

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

  group('Remote Team Sync & GetOrCreate Team Tests', () {
    testWidgets('Joining existing team in SettingsScreen updates team and invalidates providers', (WidgetTester tester) async {
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

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);
      when(() => mockTeamService.getTeam('team-old')).thenAnswer((_) async => oldTeam);
      when(() => mockTeamService.getAllTeams()).thenAnswer((_) async => [oldTeam, sharedTeam]);
      when(() => mockTeamService.getOrCreateTeamByName(name: 'Apple Team')).thenAnswer((_) async => sharedTeam);
      when(() => mockTeamService.updateUserTeam('user-remote', 'team-shared-123')).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestableWidget(
          const SettingsScreen(),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            teamServiceProvider.overrideWithValue(mockTeamService),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Team item to change team to "Apple Team"
      await tester.tap(find.text('Old Team'));
      await tester.pumpAndSettle();

      // ChoiceChip for Apple Team should be visible and clickable
      final chip = find.text('Apple Team');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Click Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Verify getOrCreateTeamByName was called
      verify(() => mockTeamService.getOrCreateTeamByName(name: 'Apple Team')).called(1);
      verify(() => mockTeamService.updateUserTeam('user-remote', 'team-shared-123')).called(1);
    });
  });
}
