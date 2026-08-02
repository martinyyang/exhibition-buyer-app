import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Price Conversion E2E Tests', () {
    testWidgets('Formula saves and converts prices correctly',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as team creator (first remote user)
      // Note: This assumes a test account exists
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Test123456');

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to formula management
      // First, find and tap the settings or menu icon
      final menuIcon = find.byIcon(Icons.menu);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon);
        await tester.pumpAndSettle();
      }

      // Find and tap "Exchange Formula Management" or similar
      final formulaManagementButton = find.text('Exchange Formula Management');
      if (formulaManagementButton.evaluate().isNotEmpty) {
        await tester.tap(formulaManagementButton);
        await tester.pumpAndSettle();
      }

      // Set formula: RMB/6.75
      final formulaField = find.byType(TextField).first;
      await tester.enterText(formulaField, 'RMB/6.75');
      await tester.pumpAndSettle();

      // Verify preview shows correct calculations
      // ¥1000 → 148.15
      expect(find.text('148.15'), findsOneWidget);
      // ¥2000 → 296.30
      expect(find.text('296.30'), findsOneWidget);
      // ¥5000 → 740.74
      expect(find.text('740.74'), findsOneWidget);

      // Save the formula
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify success message
      expect(find.text('Formula saved successfully'), findsOneWidget);

      // Navigate back to photo screen
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Navigate to a photo detail screen
      // (Assuming there's at least one photo available)
      final photoTile = find.byType(GridTile).first;
      if (photoTile.evaluate().isNotEmpty) {
        await tester.tap(photoTile);
        await tester.pumpAndSettle();
      }

      // Tap on photo to add flag
      final gestureDetector = find.byType(GestureDetector).first;
      await tester.tap(gestureDetector);
      await tester.pumpAndSettle();

      // Enter seller price: 1000
      final priceField = find.byKey(const Key('seller_price_field'));
      if (priceField.evaluate().isNotEmpty) {
        await tester.enterText(priceField, '1000');
        await tester.pumpAndSettle();

        // Verify converted price shows 148.15
        expect(find.text('148.15'), findsOneWidget);
      }

      // Test another price: 2000
      await tester.enterText(priceField, '2000');
      await tester.pumpAndSettle();

      // Verify converted price shows 296.30
      expect(find.text('296.30'), findsOneWidget);

      // Test another price: 5000
      await tester.enterText(priceField, '5000');
      await tester.pumpAndSettle();

      // Verify converted price shows 740.74
      expect(find.text('740.74'), findsOneWidget);
    });

    testWidgets('Non-creator cannot modify formula',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as non-creator (second remote user)
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'remote2@example.com');
      await tester.enterText(passwordField, 'Test123456');

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to formula management
      final menuIcon = find.byIcon(Icons.menu);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon);
        await tester.pumpAndSettle();
      }

      final formulaManagementButton = find.text('Exchange Formula Management');
      if (formulaManagementButton.evaluate().isNotEmpty) {
        await tester.tap(formulaManagementButton);
        await tester.pumpAndSettle();
      }

      // Verify permission warning is shown
      expect(
        find.text('Only the team creator can modify the exchange formula.'),
        findsOneWidget,
      );

      // Verify formula field is disabled
      final formulaField = find.byType(TextField).first;
      final textField = tester.widget<TextField>(formulaField);
      expect(textField.enabled, false);

      // Verify save button is disabled
      final saveButton = find.text('Save');
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: saveButton, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, null);
    });

    testWidgets('Formula persists across sessions',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Test123456');

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to formula management
      final menuIcon = find.byIcon(Icons.menu);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon);
        await tester.pumpAndSettle();
      }

      final formulaManagementButton = find.text('Exchange Formula Management');
      if (formulaManagementButton.evaluate().isNotEmpty) {
        await tester.tap(formulaManagementButton);
        await tester.pumpAndSettle();
      }

      // Verify current formula is displayed (RMB/6.75 from previous test)
      expect(find.text('RMB/6.75'), findsAtLeastNWidgets(1));
    });

    testWidgets('Multiple formulas in history', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as team creator
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Test123456');

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to formula management
      final menuIcon = find.byIcon(Icons.menu);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon);
        await tester.pumpAndSettle();
      }

      final formulaManagementButton = find.text('Exchange Formula Management');
      if (formulaManagementButton.evaluate().isNotEmpty) {
        await tester.tap(formulaManagementButton);
        await tester.pumpAndSettle();
      }

      // Set new formula: RMB/7.0
      final formulaField = find.byType(TextField).first;
      await tester.enterText(formulaField, 'RMB/7.0');
      await tester.pumpAndSettle();

      // Save the formula
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify both formulas appear in history
      expect(find.text('RMB/6.75'), findsOneWidget);
      expect(find.text('RMB/7.0'), findsAtLeastNWidgets(1));

      // Tap on history formula to reuse it
      final historyChip = find.text('RMB/6.75');
      await tester.tap(historyChip);
      await tester.pumpAndSettle();

      // Verify formula field is populated
      final textField = tester.widget<TextField>(formulaField);
      expect(textField.controller?.text, 'RMB/6.75');
    });
  });
}
