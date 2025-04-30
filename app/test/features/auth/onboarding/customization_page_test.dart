import 'package:acter/features/onboarding/pages/customization_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_util.dart';

void main() {
  late SharedPreferences prefs;
  late VoidCallback mockCallNextPage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await sharedPrefs();
    mockCallNextPage = () {};
  });

  testWidgets('CustomizationPage displays all required elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: CutomizationPage(callNextPage: mockCallNextPage),
    );

    // Verify headline text
    expect(find.text('Your Acter'), findsOneWidget);

    // Verify title text
    expect(find.text('What are you going to organize?'), findsOneWidget);

    // Verify all organization cards are present
    expect(find.byType(Card), findsNWidgets(9));
  });

  testWidgets('Card selection updates SharedPreferences', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: CutomizationPage(callNextPage: mockCallNextPage),
    );

    // Find and tap the first card
    final firstCard = find.byType(Card).first;
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    // Verify SharedPreferences was updated
    final selectedItems = prefs.getStringList('selected_organizations') ?? [];
    expect(selectedItems.length, 1);
    expect(selectedItems.first, 'Activism');

    // Tap again to deselect
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    // Verify item was removed from SharedPreferences
    final updatedItems = prefs.getStringList('selected_organizations') ?? [];
    expect(updatedItems.isEmpty, true);
  });

  testWidgets('action buttons', (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: CutomizationPage(callNextPage: mockCallNextPage),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Card visual feedback on selection', (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: CutomizationPage(callNextPage: mockCallNextPage),
    );

    // Get the first card
    final firstCard = find.byType(Card).first;
    final cardWidget = tester.widget<Card>(firstCard);

    // Verify initial state (no border)
    expect(
      (cardWidget.shape as RoundedRectangleBorder).side.color,
      Colors.transparent,
    );

    // Tap the card
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    // Get the updated card
    final updatedCardWidget = tester.widget<Card>(firstCard);

    // Verify border color changed
    expect(
      (updatedCardWidget.shape as RoundedRectangleBorder).side.color,
      isNot(Colors.transparent),
    );
  });
}
