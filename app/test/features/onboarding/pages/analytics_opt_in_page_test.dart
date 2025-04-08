import 'package:acter/features/onboarding/pages/analytics_opt_in_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('AnalyticsOptInPage Tests', () {
    testWidgets('Initial state shows all toggles in default state', (
      WidgetTester tester,
    ) async {
      // Set up initial state
      SharedPreferences.setMockInitialValues({
        'basicTelemetry': false,
        'appAnalytics': false,
        'research': false,
        'allowToReportToSentry': false,
      });

      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Verify initial state of toggles
      expect(
        find.byType(Switch),
        findsNWidgets(5),
      ); // 4 individual + 1 toggle all
      expect(find.text('Toggle All'), findsOneWidget);
    });

    testWidgets('Toggle All enables all analytics options', (
      WidgetTester tester,
    ) async {
      // Set up initial state
      SharedPreferences.setMockInitialValues({
        'basicTelemetry': false,
        'appAnalytics': false,
        'research': false,
        'allowToReportToSentry': false,
      });

      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();
      // Find the Toggle All switch
      final toggleAllText = find.text('Toggle All');
      expect( 
        toggleAllText,
        findsOneWidget,
        reason: 'Toggle All text not found',
      );

      final toggleAllRow = find.ancestor(
        of: toggleAllText,
        matching: find.byType(Row),
      );
      expect(toggleAllRow, findsOneWidget, reason: 'Toggle All row not found');

      final toggleAllSwitch = find.descendant(
        of: toggleAllRow,
        matching: find.byType(Switch),
      );
      expect(
        toggleAllSwitch,
        findsOneWidget,
        reason: 'Toggle All switch not found',
      );

      // Tap the switch and wait for animations
      await tester.tap(toggleAllSwitch);
      await tester.pump();

      // Wait for the async operations to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify the state was updated
      final prefs = await sharedPrefs();
      expect(prefs.getBool('basicTelemetry'), true);
      expect(prefs.getBool('appAnalytics'), true);
      expect(prefs.getBool('research'), true);
      expect(prefs.getBool('allowToReportToSentry'), true);
    });

    testWidgets('Toggle All is enabled only when all options are on', (
      WidgetTester tester,
    ) async {
      // Set up all options enabled
      SharedPreferences.setMockInitialValues({
        'basicTelemetry': true,
        'appAnalytics': true,
        'research': true,
        'allowToReportToSentry': true,
      });

      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the Toggle All switch
      final toggleAllText = find.text('Toggle All');
      expect(
        toggleAllText,
        findsOneWidget,
        reason: 'Toggle All text not found',
      );

      final toggleAllRow = find.ancestor(
        of: toggleAllText,
        matching: find.byType(Row),
      );
      expect(toggleAllRow, findsOneWidget, reason: 'Toggle All row not found');

      final toggleAllSwitch = find.descendant(
        of: toggleAllRow,
        matching: find.byType(Switch),
      );
      expect(
        toggleAllSwitch,
        findsOneWidget,
        reason: 'Toggle All switch not found',
      );

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // Verify Toggle All is enabled
      final switchWidget = tester.widget<Switch>(toggleAllSwitch);
      expect(
        switchWidget.value,
        isTrue,
        reason: 'Toggle All switch should be enabled when all options are on',
      );
    });

    testWidgets('Toggle All disables all analytics options', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();
      // Find the Toggle All switch
      final toggleAllText = find.text('Toggle All');
      expect(
        toggleAllText,
        findsOneWidget,
        reason: 'Toggle All text not found',
      );

      final toggleAllRow = find.ancestor(
        of: toggleAllText,
        matching: find.byType(Row),
      );
      expect(toggleAllRow, findsOneWidget, reason: 'Toggle All row not found');

      final toggleAllSwitch = find.descendant(
        of: toggleAllRow,
        matching: find.byType(Switch),
      );
      expect(
        toggleAllSwitch,
        findsOneWidget,
        reason: 'Toggle All switch not found',
      );

      // Tap the switch and wait for animations
      await tester.tap(toggleAllSwitch);
      await tester.pump();

      // Wait for the async operations to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      SharedPreferences.setMockInitialValues({
        'basicTelemetry': false,
        'appAnalytics': false,
        'research': false,
        'allowToReportToSentry': false,
      });

      final prefs = await sharedPrefs();
      expect(prefs.getBool('basicTelemetry'), false);
      expect(prefs.getBool('appAnalytics'), false);
      expect(prefs.getBool('research'), false);
      expect(prefs.getBool('allowToReportToSentry'), false);
    });

    testWidgets('Toggle All is disabled when any option is off', (
      WidgetTester tester,
    ) async {
      // Set up mixed state: some enabled, some disabled
      SharedPreferences.setMockInitialValues({
        'basicTelemetry': true,
        'appAnalytics': false,
        'research': true,
        'allowToReportToSentry': false,
      });

      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the Toggle All switch
      final toggleAllText = find.text('Toggle All');
      expect(
        toggleAllText,
        findsOneWidget,
        reason: 'Toggle All text not found',
      );

      final toggleAllRow = find.ancestor(
        of: toggleAllText,
        matching: find.byType(Row),
      );
      expect(toggleAllRow, findsOneWidget, reason: 'Toggle All row not found');

      final toggleAllSwitch = find.descendant(
        of: toggleAllRow,
        matching: find.byType(Switch),
      );
      expect(
        toggleAllSwitch,
        findsOneWidget,
        reason: 'Toggle All switch not found',
      );

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // Verify Toggle All is disabled
      final switchWidget = tester.widget<Switch>(toggleAllSwitch);
      expect(
        switchWidget.value,
        isFalse,
        reason: 'Toggle All switch should be disabled when any option is off',
      );
    });

    testWidgets('Toggle All is disabled when sentry reporting is false', (
      WidgetTester tester,
    ) async {
      // Set up initial state with all preferences enabled
      SharedPreferences.setMockInitialValues({
        'basicTelemetry': true,
        'appAnalytics': true,
        'research': true,
        'allowToReportToSentry': true,
      });

      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => false),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the Toggle All switch
      final toggleAllText = find.text('Toggle All');
      expect(
        toggleAllText,
        findsOneWidget,
        reason: 'Toggle All text not found',
      );

      final toggleAllRow = find.ancestor(
        of: toggleAllText,
        matching: find.byType(Row),
      );
      expect(toggleAllRow, findsOneWidget, reason: 'Toggle All row not found');

      final toggleAllSwitch = find.descendant(
        of: toggleAllRow,
        matching: find.byType(Switch),
      );
      expect(
        toggleAllSwitch,
        findsOneWidget,
        reason: 'Toggle All switch not found',
      );

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // Verify Toggle All is disabled
      final switchWidget = tester.widget<Switch>(toggleAllSwitch);
      expect(
        switchWidget.value,
        isFalse,
        reason:
            'Toggle All switch should be disabled when sentry reporting is false',
      );
    });

    testWidgets('Individual toggle updates affect Toggle All state', (
      WidgetTester tester,
    ) async {
      // Start with all options enabled
      SharedPreferences.setMockInitialValues({
        'basicTelemetry': true,
        'appAnalytics': true,
        'research': true,
        'allowToReportToSentry': true,
      });

      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the first individual switch (not the Toggle All switch)
      final allSwitches = find.byType(Switch);
      expect(
        allSwitches,
        findsNWidgets(5),
        reason: 'Should find 5 switches (4 individual + 1 toggle all)',
      );

      // Get the first individual switch (skip the Toggle All switch)
      final firstIndividualSwitch = allSwitches.at(1);
      expect(
        firstIndividualSwitch,
        findsOneWidget,
        reason: 'First individual switch not found',
      );

      // Tap the switch and wait for animations
      await tester.tap(firstIndividualSwitch);
      await tester.pump();

      // Wait for the async operations to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Find the Toggle All switch
      final toggleAllText = find.text('Toggle All');
      expect(
        toggleAllText,
        findsOneWidget,
        reason: 'Toggle All text not found',
      );

      final toggleAllRow = find.ancestor(
        of: toggleAllText,
        matching: find.byType(Row),
      );
      expect(toggleAllRow, findsOneWidget, reason: 'Toggle All row not found');

      final toggleAllSwitch = find.descendant(
        of: toggleAllRow,
        matching: find.byType(Switch),
      );
      expect(
        toggleAllSwitch,
        findsOneWidget,
        reason: 'Toggle All switch not found',
      );

      // Verify Toggle All is now disabled
      final switchWidget = tester.widget<Switch>(toggleAllSwitch);
      expect(
        switchWidget.value,
        isFalse,
        reason:
            'Toggle All switch should be disabled after toggling an individual switch',
      );
    });

    testWidgets('Continue button is present and clickable', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the continue button
      final continueButton = find.byKey(AnalyticsOptInPage.continueBtn);
      expect(
        continueButton,
        findsOneWidget,
        reason: 'Continue button not found',
      );

      // Verify it's a PrimaryActionButton
      final buttonWidget = tester.widget<ElevatedButton>(continueButton);
      expect(
        buttonWidget,
        isNotNull,
        reason: 'Continue button should be an ElevatedButton',
      );
    });

    testWidgets('Skip button is present and clickable', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the skip button
      final skipButton = find.byType(OutlinedButton);
      expect(skipButton, findsOneWidget, reason: 'Skip button not found');

      // Verify it's an OutlinedButton
      final buttonWidget = tester.widget<OutlinedButton>(skipButton);
      expect(
        buttonWidget,
        isNotNull,
        reason: 'Skip button should be an OutlinedButton',
      );
    });

    testWidgets('More Details link is present and clickable', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          allowSentryReportingProvider.overrideWith((ref) => true),
          allowMatomoAnalyticsProvider.overrideWith((ref) => true),
        ],
        child: AnalyticsOptInPage(),
      );

      // Wait for the FutureBuilder to complete
      await tester.pumpAndSettle();

      // Find the more details text
      final moreDetailsText = find.text(
        'More details and further ways to contribute.',
      );
      expect(moreDetailsText, findsOneWidget);

      // Verify it's a Text widget with the correct style
      final textWidget = tester.widget<Text>(moreDetailsText);
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });
  });
}
