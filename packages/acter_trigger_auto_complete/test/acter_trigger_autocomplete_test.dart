import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render fine', (tester) async {
    const multiTriggerAutocompleteKey = Key('multiTriggerAutocomplete');
    final multiTriggerAutocomplete = Boilerplate(
      child: MultiTriggerAutocomplete(
        key: multiTriggerAutocompleteKey,
        autocompleteTriggers: const [],
        textEditingController: ActerTriggerAutoCompleteTextController(),
        focusNode: FocusNode(),
      ),
    );

    await tester.pumpWidget(multiTriggerAutocomplete);

    expect(find.byKey(multiTriggerAutocompleteKey), findsOneWidget);
  });

  group('MultiTriggerAutocomplete', () {
    const kUsers = [
      User(id: 'xsahil03x', name: 'Sahil Kumar'),
      User(id: 'avu.saxena', name: 'Avni Saxena'),
      User(id: 'trapti2711', name: 'Trapti Gupta'),
      User(id: 'itsmegb98', name: 'Gaurav Bhadouriya'),
      User(id: 'amitk_15', name: 'Amit Kumar'),
      User(id: 'ayushpgupta', name: 'Ayush Gupta'),
      User(id: 'someshubham', name: 'Shubham Jain'),
    ];

    const kDebounceDuration = Duration(milliseconds: 300);
    final mentionTrigger = AutocompleteTrigger(
      trigger: '@',
      optionsViewBuilder: (context, autocompleteQuery, controller) {
        final query = autocompleteQuery.query;
        final filteredUsers = kUsers.where((user) {
          return user.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return ListTile(
              title: Text(user.name),
              onTap: () {
                final autocomplete = MultiTriggerAutocomplete.of(context);
                return autocomplete.acceptAutocompleteOption(user.name);
              },
            );
          },
        );
      },
    );

    testWidgets(
      'can filter and select a list of string options',
      (tester) async {
        await tester.pumpWidget(
          Boilerplate(
            child: MultiTriggerAutocomplete(
              debounceDuration: kDebounceDuration,
              autocompleteTriggers: [mentionTrigger],
              textEditingController: ActerTriggerAutoCompleteTextController(),
              focusNode: FocusNode(),
            ),
          ),
        );

        // The field is always rendered, but the options are not unless needed.
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        // Entering the trigger text. All the options are displayed.
        await tester.enterText(find.byType(TextFormField), '@');
        await tester.pumpAndSettle(kDebounceDuration);
        expect(find.byType(ListView), findsOneWidget);
        ListView list =
            find.byType(ListView).evaluate().first.widget as ListView;
        expect(list.semanticChildCount, kUsers.length);

        // Enter query text. The options are filtered by the text.
        await tester.enterText(find.byType(TextFormField), '@sa');
        await tester.pumpAndSettle(kDebounceDuration);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        list = find.byType(ListView).evaluate().first.widget as ListView;
        // '@Sahil kumar' and '@Avni Saxena' are displayed.
        expect(list.semanticChildCount, 2);

        // Select a option. The options hide and the field updates to show the
        // selection.
        await tester.tap(find.byType(InkWell).first);
        await tester.pump();
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
        final TextFormField field =
            find.byType(TextFormField).evaluate().first.widget as TextFormField;
        expect(field.controller!.text, '@Sahil Kumar ');

        // Modify the field text. The options appear again and are filtered.
        await tester.enterText(find.byType(TextFormField), '@av');
        await tester.pumpAndSettle(kDebounceDuration);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        list = find.byType(ListView).evaluate().first.widget as ListView;
        // '@Avni Saxena' and '@Gaurav Bhadouriya' are displayed.
        expect(list.semanticChildCount, 2);
      },
    );

    testWidgets(
      'options position changes when alignment changed',
      (tester) async {
        late StateSetter setState;
        OptionsAlignment alignment = OptionsAlignment.bottom;
        await tester.pumpWidget(
          Boilerplate(
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return MultiTriggerAutocomplete(
                  optionsAlignment: alignment,
                  debounceDuration: kDebounceDuration,
                  autocompleteTriggers: [mentionTrigger],
                  textEditingController:
                      ActerTriggerAutoCompleteTextController(),
                  focusNode: FocusNode(),
                );
              },
            ),
          ),
        );

        // Field is shown but not options.
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        // Enter text to show the options.
        await tester.enterText(find.byType(TextFormField), '@');
        await tester.pumpAndSettle(kDebounceDuration);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        // Options are just below the field.
        final optionsOffset = tester.getTopLeft(find.byType(ListView));
        Offset fieldOffset = tester.getTopLeft(find.byType(TextFormField));
        final fieldSize = tester.getSize(find.byType(TextFormField));
        expect(optionsOffset.dy, fieldOffset.dy + fieldSize.height);

        // Changing the alignment should change the position of options.
        setState(() => alignment = OptionsAlignment.top);
        await tester.pump();
        fieldOffset = tester.getBottomLeft(find.byType(TextFormField));
        final optionsOffsetOpen = tester.getBottomLeft(find.byType(ListView));
        expect(optionsOffsetOpen.dy, isNot(equals(optionsOffset.dy)));
        expect(optionsOffsetOpen.dy, fieldOffset.dy - fieldSize.height);
      },
    );

    testWidgets('can build a custom field', (WidgetTester tester) async {
      const fieldKey = Key('fieldKey');
      await tester.pumpWidget(
        Boilerplate(
          child: MultiTriggerAutocomplete(
            autocompleteTriggers: [mentionTrigger],
            fieldViewBuilder: (context, controller, focusNode) {
              return Container(key: fieldKey);
            },
            textEditingController: ActerTriggerAutoCompleteTextController(),
            focusNode: FocusNode(),
          ),
        ),
      );

      // The custom field is rendered and not the default TextFormField.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  });

  group('Regex tests', () {
    final regex = RegExp('\\@\\S+(?: \\S+)*(?=\\s)');

    test(
        'should match strings starting with trigger word followed by one or more non-whitespace characters',
        () {
      expect(regex.hasMatch('@John '), isTrue);
      expect(regex.hasMatch('@JohnDoe '), isTrue);
      expect(regex.hasMatch('@John_Doe '), isTrue);
    });

    test(
        'should match strings starting with trigger word followed by multiple groups of non-whitespace characters separated by spaces',
        () {
      expect(regex.hasMatch('@John Doe '), isTrue);
      expect(regex.hasMatch('@John Doe Smith '), isTrue);
    });

    test('should not match strings without trigger word', () {
      expect(regex.hasMatch('John '), isFalse);
      expect(regex.hasMatch('John Doe '), isFalse);
    });

    test('should not match strings with only trigger word', () {
      expect(regex.hasMatch('@ '), isFalse);
    });

    test('should match strings with trailing non-whitespace characters', () {
      expect(regex.hasMatch('@John '), isTrue);
      expect(regex.hasMatch('@John Doe '), isTrue);
    });
  });
}

class User {
  const User({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class Boilerplate extends StatelessWidget {
  const Boilerplate({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }
}
