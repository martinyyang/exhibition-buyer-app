import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Web Registration E2E Tests', () {
    testWidgets('Complete registration flow', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.text('Login'), findsOneWidget);

      // Navigate to registration
      final registerButton = find.text('Register');
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Fill registration form
      final emailField = find.byType(TextField).first;
      await tester.enterText(
          emailField, 'e2e_${DateTime.now().millisecondsSinceEpoch}@test.com');
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'Test123456');
      await tester.pumpAndSettle();

      final confirmPasswordField = find.byType(TextField).at(2);
      await tester.enterText(confirmPasswordField, 'Test123456');
      await tester.pumpAndSettle();

      final teamNameField = find.byType(TextField).at(3);
      await tester.enterText(teamNameField, 'E2E Test Team');
      await tester.pumpAndSettle();

      // Select Buyer role (should be selected by default)
      // Tap register button
      final submitButton = find.text('Register');
      await tester.tap(submitButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to event selection
      expect(find.text('Select Event'), findsOneWidget);
    });

    testWidgets('Registration validation - password mismatch',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Fill form with mismatched passwords
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password1');
      await tester.enterText(find.byType(TextField).at(2), 'Password2');
      await tester.enterText(find.byType(TextField).at(3), 'Test Team');
      await tester.pumpAndSettle();

      // Tap register
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.textContaining('match'), findsOneWidget);
    });

    testWidgets('Login flow after registration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'test@123.com');
      await tester.enterText(find.byType(TextField).at(1), 'Test123456');
      await tester.pumpAndSettle();

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate to event selection
      expect(find.text('Select Event'), findsOneWidget);
    });
  });
}
