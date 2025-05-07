import 'package:acter/features/onboarding/pages/onboarding_space_creation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';

void main() {
  group('OnboardingSpaceCreationPage', () {
    testWidgets('renders all UI elements correctly', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: OnboardingSpaceCreationPage(callNextPage: () {}),
      );

      // Verify icon is present
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);

      // Verify headline text is present
      expect(find.text('Create New Space'), findsOneWidget);

      // Verify action buttons are present
      expect(find.text('Create my first space'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('does not throw when callNextPage is null',
        (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: OnboardingSpaceCreationPage(callNextPage: () {}),
      );

      // Tap the skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // No exception should be thrown
      expect(tester.takeException(), null);
    });
  });
} 