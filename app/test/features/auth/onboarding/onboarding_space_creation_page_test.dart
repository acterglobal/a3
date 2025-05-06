import 'package:acter/features/onboarding/pages/onboarding_space_creation_page.dart';
import 'package:acter/features/onboarding/widgets/create_new_space_widget.dart';
import 'package:acter/common/widgets/input_text_field_without_border.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';

void main() {
  group('OnboardingSpaceCreationPage', () {
    testWidgets('renders all UI elements correctly', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: const OnboardingSpaceCreationPage(callNextPage: null),
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
        child: const OnboardingSpaceCreationPage(callNextPage: null),
      );

      // Tap the skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // No exception should be thrown
      expect(tester.takeException(), null);
    });
  });
} 