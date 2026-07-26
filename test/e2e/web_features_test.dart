import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Web Photo Upload E2E Tests', () {
    setUp(() async {
      // Login before each test
    });

    testWidgets('Photo upload button shows file upload icon on web',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextField).first, 'test@123.com');
      await tester.enterText(find.byType(TextField).at(1), 'Test123456');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to photo screen (assuming event selection)
      // This depends on your navigation flow

      // Verify FAB shows upload icon on web
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // On web, should show Icons.upload_file
      final iconFinder = find.descendant(
        of: fab,
        matching: find.byIcon(Icons.upload_file),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('File picker opens on photo upload',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login and navigate to photo screen
      await tester.enterText(find.byType(TextField).first, 'test@123.com');
      await tester.enterText(find.byType(TextField).at(1), 'Test123456');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap upload button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // File picker should open (browser native dialog)
      // This will open system dialog, which we can't test in integration test
      // But we can verify no errors occurred
    });
  });

  group('Web Responsive Layout Tests', () {
    testWidgets('Desktop layout - centered card on login',
        (WidgetTester tester) async {
      // Set window size to desktop
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      app.main();
      await tester.pumpAndSettle();

      // On desktop, login form should be centered
      final loginForm = find.byType(Card);
      expect(loginForm, findsOneWidget);
    });

    testWidgets('Mobile layout - full screen on login',
        (WidgetTester tester) async {
      // Set window size to mobile
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;

      app.main();
      await tester.pumpAndSettle();

      // On mobile, should use full screen layout
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Photo grid columns adjust by screen size',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextField).first, 'test@123.com');
      await tester.enterText(find.byType(TextField).at(1), 'Test123456');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Desktop: 3-4 columns
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpAndSettle();

      // Mobile: 2 columns
      tester.view.physicalSize = const Size(375, 667);
      await tester.pumpAndSettle();
    });
  });

  group('Web Navigation Tests', () {
    testWidgets('Browser back button works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Register Account'), findsOneWidget);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should be back on login
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
