import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MockOnChanged extends Mock {
  void call(String value);
}

class MockOnClear extends Mock {
  void call();
}

void main() {
  late MockOnChanged mockOnChanged;
  late MockOnClear mockOnClear;

  setUp(() {
    mockOnChanged = MockOnChanged();
    mockOnClear = MockOnClear();
  });

  Widget createWidgetUnderTest({String? hintText, String? initialText}) {
    return MaterialApp(
      localizationsDelegates: L10n.localizationsDelegates,
      home: Scaffold(
        body: ActerSearchWidget(
          hintText: hintText,
          initialText: initialText,
          onChanged: mockOnChanged.call,
          onClear: mockOnClear.call,
        ),
      ),
    );
  }

  testWidgets('displays initial text in the search bar', (tester) async {
    const initialText = 'initial search';

    await tester.pumpWidget(createWidgetUnderTest(initialText: initialText));

    final searchField = find.byKey(ActerSearchWidget.searchBarKey);
    expect(searchField, findsOneWidget);
    expect(find.text(initialText), findsOneWidget);
  });

  testWidgets('calls onChanged when text is entered', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    const inputText = 'new search';
    await tester.enterText(
      find.byKey(ActerSearchWidget.searchBarKey),
      inputText,
    );

    verify(() => mockOnChanged(inputText)).called(1);
  });

  testWidgets('calls onClear and clears text when clear button is pressed',
      (tester) async {
    await tester
        .pumpWidget(createWidgetUnderTest(initialText: 'text to clear'));

    await tester.enterText(
      find.byKey(ActerSearchWidget.searchBarKey),
      'text to clear',
    );
    await tester.pump();

    // Ensure the clear button is displayed
    final clearButton =
        find.byKey(ActerSearchWidget.clearSearchActionButtonKey);
    expect(clearButton, findsOneWidget);

    // Tap the clear button and verify behaviors
    await tester.tap(clearButton);
    await tester.pump();

    verify(() => mockOnClear()).called(1);
    expect(find.text('text to clear'), findsNothing);
  });

  testWidgets('displays hint text when there is no initial text',
      (tester) async {
    const hintText = 'Search here...';

    await tester.pumpWidget(createWidgetUnderTest(hintText: hintText));

    expect(find.text(hintText), findsOneWidget);
  });

  testWidgets('displays default leading icon if none is provided',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final leadingIcon = find.byIcon(Atlas.magnifying_glass);
    expect(leadingIcon, findsOneWidget);
  });
}
