import 'package:acter/common/widgets/acter_icon_picker/picker/acter_icon_picker.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/l10n/generated/l10n.dart';

void main() {
  // Helper function to create the widget under test
  Future<void> createWidgetUnderTest(
    WidgetTester tester, {
    required Color initialColor,
    required ActerIcon initialIcon,
    required Function(Color, ActerIcon) onIconSelection,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate, // For localization support
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showActerIconPicker(
                      context: context,
                      selectedColor: initialColor,
                      selectedIcon: initialIcon,
                      onIconSelection: onIconSelection,
                    );
                  },
                  child: const Text('Open Picker'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> performSearch(WidgetTester tester, String searchValue) async {
    // Find the search bar and enter the search value
    final searchBar = find.byKey(ActerSearchWidget.searchBarKey);
    expect(searchBar, findsOneWidget);

    // Enter the search value
    await tester.enterText(searchBar, searchValue);
    await tester.pumpAndSettle();
  }

  List<ActerIcon> filterIcons(String searchValue) {
    // Filter the icons based on the search value
    return ActerIcon.values.where((icon) {
      return icon.name.toLowerCase().contains(searchValue.toLowerCase());
    }).toList();
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Check if the bottom sheet is displayed
    expect(find.byType(ActerIconPicker), findsOneWidget);
  }

  testWidgets('ActerIconPicker displays initial color and icon correctly', (
    WidgetTester tester,
  ) async {
    await createWidgetUnderTest(
      tester,
      initialColor: Colors.red,
      initialIcon: ActerIcon.car,
      onIconSelection: (color, icon) {},
    );
    // Tap the button to open the picker
    await openPicker(tester);

    // Find the icon preview by the key set in the Icon widget inside the _buildIconPreviewUI method
    final iconPreview = find.byKey(Key('icon-preview'));

    // Ensure that the icon preview exists
    expect(iconPreview, findsOneWidget);

    // Get the actual Icon widget and verify its properties
    final iconWidget = tester.widget<Icon>(iconPreview);

    // Check if the icon is correct (based on ActerIcon.car.data)
    expect(iconWidget.icon, equals(ActerIcon.car.data));

    // Check if the icon color matches the selectedColor (red in this case)
    expect(iconWidget.color, equals(Colors.red));
  });

  testWidgets('Color selection updates the preview', (
    WidgetTester tester,
  ) async {
    // Prepare initial color and icon
    final initialColor = Colors.blue;
    final initialIcon = ActerIcon.list;
    final newColor = Colors.grey;

    // Build the widget
    await createWidgetUnderTest(
      tester,
      initialColor: initialColor,
      initialIcon: initialIcon,
      onIconSelection: (color, icon) {
        color = newColor;
      },
    );

    // Tap the button to open the picker
    await openPicker(tester);

    // Test selecting a new color
    final colorPicker = find.byKey(Key('color-picker-0'));
    await tester.tap(colorPicker); // Select a color
    await tester.pumpAndSettle();

    // Verify if the selected color has been updated in the preview
    final iconPreview = find.byKey(
      Key('icon-preview'),
    ); // Find the icon preview
    expect(iconPreview, findsOneWidget);

    // Get the actual Icon widget and verify its color
    final iconWidget = tester.widget<Icon>(iconPreview);
    expect(iconWidget.icon, equals(ActerIcon.list.data));
    expect(iconWidget.color, equals(newColor));
  });

  testWidgets('Icon selection updates the preview', (
    WidgetTester tester,
  ) async {
    // Prepare initial color and icon
    final initialColor = Colors.blue;
    final initialIcon = ActerIcon.list;
    final newIcon = ActerIcon.pin;

    // Build the widget
    await createWidgetUnderTest(
      tester,
      initialColor: initialColor,
      initialIcon: initialIcon,
      onIconSelection: (color, icon) {
        icon = newIcon;
      },
    );

    // Tap the button to open the picker
    await openPicker(tester);

    // Ensure widget tree is fully rendered
    await tester.pumpAndSettle();

    final iconPicker = find.byKey(Key('icon-picker-1'));
    await tester.tap(iconPicker); // Select a new icon
    await tester.pumpAndSettle();

    // Verify if the selected color has been updated in the preview
    final iconPreview = find.byKey(
      Key('icon-preview'),
    ); // Find the icon preview
    expect(iconPreview, findsOneWidget);

    // Get the actual Icon widget and verify its color
    final iconWidget = tester.widget<Icon>(iconPreview);
    expect(iconWidget.icon, equals(newIcon.data));
  });

  testWidgets(
    'Action button triggers the onIconSelection callback with correct values',
    (WidgetTester tester) async {
      // Prepare initial color, icon, and the callback
      final initialColor = Colors.blue;
      final initialIcon = ActerIcon.list;
      final newIcon = ActerIcon.pin;

      ActerIcon? callbackIcon;

      // Build the widget
      await createWidgetUnderTest(
        tester,
        initialColor: initialColor,
        initialIcon: initialIcon,
        onIconSelection: (color, icon) {
          callbackIcon = icon;
        },
      );

      // Tap the button to open the picker
      await openPicker(tester);

      // Ensure widget tree is fully rendered
      await tester.pumpAndSettle();

      // Simulate selecting an icon
      await tester.tap(find.byKey(Key('icon-picker-1'))); // Calendar
      await tester.pumpAndSettle();

      // Tap the action button to confirm the selection
      await tester.tap(find.byKey(Key('acter-primary-action-button')));
      await tester.pumpAndSettle();

      expect(
        callbackIcon,
        equals(newIcon),
      ); // The callback should have the new icon
    },
  );

  testWidgets('Search widget is displayed in icon picker', (
    WidgetTester tester,
  ) async {
    await createWidgetUnderTest(
      tester,
      initialColor: Colors.blue,
      initialIcon: ActerIcon.list,
      onIconSelection: (color, icon) {},
    );

    // Tap the button to open the picker
    await openPicker(tester);

    // Check if the search widget is present
    expect(find.byKey(ActerSearchWidget.searchBarKey), findsOneWidget);
  });

  testWidgets('Search shows correct icons for specific search term', (
    WidgetTester tester,
  ) async {
    await createWidgetUnderTest(
      tester,
      initialColor: Colors.blue,
      initialIcon: ActerIcon.list,
      onIconSelection: (color, icon) {},
    );

    // Tap the button to open the picker
    await openPicker(tester);

    // Perform search for 'car'
    await performSearch(tester, 'car');

    // Find the expected icons that contain 'car' in their name
    final expectedIcons = filterIcons('car');

    // Verify that only matching icons are displayed
    expect(expectedIcons.isNotEmpty, true);

    // Verify that the list icon is displayed
    expect(find.byIcon(ActerIcon.list.data), findsOneWidget);

    // Find the expected car icon because it's the search result
    for (final icon in expectedIcons) {
      expect(find.byIcon(icon.data), findsOneWidget);
    }
  });

  testWidgets('Search with no matching results shows empty list', (
    WidgetTester tester,
  ) async {
    await createWidgetUnderTest(
      tester,
      initialColor: Colors.blue,
      initialIcon: ActerIcon.list,
      onIconSelection: (color, icon) {},
    );

    // Tap the button to open the picker
    await openPicker(tester);

    // Search for something that doesn't exist
    await performSearch(tester, 'nonexistenticon');

    // Verify that no icons are displayed
    final noIconsFound = find.byKey(Key('no-icons-found'));
    expect(noIconsFound, findsOneWidget);
  });

  testWidgets('Search with case insensitive', (WidgetTester tester) async {
    await createWidgetUnderTest(
      tester,
      initialColor: Colors.blue,
      initialIcon: ActerIcon.list,
      onIconSelection: (color, icon) {},
    );

    // Tap the button to open the picker
    await openPicker(tester);

    // Perform search for 'CAR' with uppercase
    await performSearch(tester, 'CAR');

    // Find the expected icons that contain 'CAR' in their name
    final expectedIcons = filterIcons('CAR');

    // Verify that only matching icons are displayed
    expect(expectedIcons.isNotEmpty, true);

    // Find the expected list icon because it's initial icon
    expect(find.byIcon(ActerIcon.list.data), findsOneWidget);

    // Find the expected car icon because it's the search result
    for (final icon in expectedIcons) {
      expect(find.byIcon(icon.data), findsOneWidget);
    }
  });
}
