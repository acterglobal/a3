import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/features/onboarding/widgets/create_new_space_widget.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/test_util.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockBuildContext());
  });

  group('CreateNewSpaceWidget', () {
    testWidgets('renders all UI elements correctly', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: CreateNewSpaceWidget(callNextPage: () {}),
        overrides: [
          accountDisplayNameProvider.overrideWith((ref) => Future.value('Test User')),
          featureActivationStateProvider.overrideWith((ref) => {}),
        ],
      );

      // Verify headline text is present
      expect(find.text('Create New Space'), findsOneWidget);

      // Verify avatar section is present
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

      // Verify space name input field is present
      expect(find.byType(InputTextField), findsOneWidget);

      // Verify checkboxes are present
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Verify action button is present
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('updates space name when text is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: CreateNewSpaceWidget(callNextPage: () {}),
        overrides: [
          accountDisplayNameProvider.overrideWith((ref) => Future.value('Test User')),
          featureActivationStateProvider.overrideWith((ref) => {}),
        ],
      );

      // Find the text field and enter text
      final textField = find.byType(InputTextField);
      await tester.enterText(textField, 'Test Space Name');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('Test Space Name'), findsOneWidget);
    });

    testWidgets('toggles checkboxes when tapped', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: CreateNewSpaceWidget(callNextPage: () {}),
        overrides: [
          accountDisplayNameProvider.overrideWith((ref) => Future.value('Test User')),
          featureActivationStateProvider.overrideWith((ref) => {}),
        ],
      );

      // Find both checkboxes
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(2));

      // Tap first checkbox
      await tester.tap(checkboxes.first);
      await tester.pump();

      // Tap second checkbox
      await tester.tap(checkboxes.last);
      await tester.pump();

      // Verify checkboxes are toggled
      final firstCheckbox = tester.widget<Checkbox>(checkboxes.first);
      final secondCheckbox = tester.widget<Checkbox>(checkboxes.last);
      expect(firstCheckbox.value, false);
      expect(secondCheckbox.value, false);
    });
  });
}