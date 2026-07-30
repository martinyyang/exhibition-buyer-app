import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:exhibition_buyer_app/features/auth/models/user.dart' as app_user;
import 'package:exhibition_buyer_app/features/auth/models/team.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/photo/services/photo_service.dart';
import 'package:exhibition_buyer_app/features/booth/services/booth_service.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';
import 'package:exhibition_buyer_app/features/team/providers/team_provider.dart';
import 'package:exhibition_buyer_app/features/team/services/team_service.dart';
import 'package:exhibition_buyer_app/features/event/providers/event_provider.dart';
import 'package:exhibition_buyer_app/features/booth/providers/booth_provider.dart';
import 'package:exhibition_buyer_app/features/photo/providers/photo_provider.dart';
import 'package:exhibition_buyer_app/features/auth/screens/register_screen.dart';
import 'package:exhibition_buyer_app/features/settings/screens/settings_screen.dart';
import 'package:exhibition_buyer_app/features/booth/screens/booth_list_screen.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_grid_screen.dart';
import 'package:exhibition_buyer_app/shared/widgets/safe_back_button.dart';

class MockAuthService extends Mock implements AuthService {}
class MockTeamService extends Mock implements TeamService {}
class MockRealtimeChannel extends Fake implements RealtimeChannel {}

class MockRealtimeService extends Mock implements RealtimeService {
  MockRealtimeService() {
    when(() => subscribeToPhotos(any(), any())).thenReturn(MockRealtimeChannel());
    when(() => subscribeToBooths(any(), any())).thenReturn(MockRealtimeChannel());
    when(() => unsubscribe(any())).thenAnswer((_) async {});
  }
}

class MockBoothService extends Mock implements BoothService {
  MockBoothService() {
    when(() => getBooths(eventId: any(named: 'eventId'), teamId: any(named: 'teamId'))).thenAnswer((_) async => []);
  }
}

class MockPhotoService extends Mock implements PhotoService {
  MockPhotoService() {
    when(() => getPhotos(any())).thenAnswer((_) async => []);
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

  setUpAll(() {
    registerFallbackValue(MockRealtimeChannel());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockTeamService = MockTeamService();
  });

  group('TDD Team Registration & Navigation Tests', () {
    testWidgets('1. SettingsScreen should display team modification dialog on tap', (WidgetTester tester) async {
      final mockUser = app_user.User(
        id: 'user-123',
        email: 'test@example.com',
        role: 'buyer',
        teamId: 'team-123',
        createdAt: DateTime.now(),
      );

      final mockTeam = Team(
        id: 'team-123',
        name: 'Alpha Team',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);
      when(() => mockTeamService.getTeam('team-123')).thenAnswer((_) async => mockTeam);
      when(() => mockTeamService.getAllTeams()).thenAnswer((_) async => [mockTeam]);

      await tester.pumpWidget(
        createTestableWidget(
          const SettingsScreen(),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            teamServiceProvider.overrideWithValue(mockTeamService),
            currentUserDataProvider.overrideWith((ref) => Future.value(mockUser)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify user and team info are displayed
      expect(find.textContaining('Alpha Team'), findsOneWidget);

      // Verify SafeBackButton exists in SettingsScreen AppBar
      expect(find.byType(SafeBackButton), findsOneWidget);

      // Tap on Team ListTile to open edit team dialog
      await tester.tap(find.textContaining('Alpha Team'));
      await tester.pumpAndSettle();

      // Check if edit team dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('2. BoothListScreen should contain SafeBackButton in AppBar', (WidgetTester tester) async {
      when(() => mockAuthService.currentUserId).thenReturn('user-123');

      final mockBoothService = MockBoothService();
      final mockRealtimeService = MockRealtimeService();

      await tester.pumpWidget(
        createTestableWidget(
          const BoothListScreen(eventId: 'event-123'),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            boothServiceProvider.overrideWithValue(mockBoothService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            eventProvider('event-123').overrideWith((ref) => Future.value(Event(
              id: 'event-123',
              name: 'Test Event',
              startDate: DateTime.now(),
              teamId: 'team-123',
              isActive: true,
              createdAt: DateTime.now(),
            ))),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify SafeBackButton exists
      expect(find.byType(SafeBackButton), findsOneWidget);
    });

    testWidgets('3. PhotoGridScreen should contain SafeBackButton in AppBar', (WidgetTester tester) async {
      final mockPhotoService = MockPhotoService();
      final mockRealtimeService = MockRealtimeService();

      await tester.pumpWidget(
        createTestableWidget(
          const PhotoGridScreen(boothId: 'booth-123'),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify SafeBackButton exists
      expect(find.byType(SafeBackButton), findsOneWidget);
    });

    testWidgets('4. RegisterScreen should have SafeBackButton to return to login', (WidgetTester tester) async {
      when(() => mockTeamService.getAllTeams()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestableWidget(
          const RegisterScreen(),
          [
            authServiceProvider.overrideWithValue(mockAuthService),
            teamServiceProvider.overrideWithValue(mockTeamService),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check for SafeBackButton in RegisterScreen
      expect(find.byType(SafeBackButton), findsOneWidget);
    });
  });
}
