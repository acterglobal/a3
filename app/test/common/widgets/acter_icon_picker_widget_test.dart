import 'package:acter/common/widgets/acter_icon_picker/picker/acter_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void main() {
  // Helper function to create the widget under test
  Future<void> createWidgetUnderTest(
    WidgetTester tester, {
    required Color initialColor,
    required ActerIcon initialIcon,
    required Function(Color, ActerIcon) onIconSelection,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
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
    );
  }

  testWidgets('ActerIconPicker displays initial color and icon correctly',
      (WidgetTester tester) async {
    await createWidgetUnderTest(
      tester,
      initialColor: Colors.red,
      initialIcon: ActerIcon.car,
      onIconSelection: (color, icon) {},
    );
    // Tap the button to open the picker
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Check if the bottom sheet is displayed
    expect(find.byType(ActerIconPicker), findsOneWidget);

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

  testWidgets('Color selection updates the preview',
      (WidgetTester tester) async {
    // Prepare initial color and icon
    final initialColor = Colors.blue;
    final initialIcon = ActerIcon.list;
    final newColor = Colors.grey;

    // Build the widget
    await createWidgetUnderTest(tester,
        initialColor: initialColor,
        initialIcon: initialIcon,
        onIconSelection: (color, icon) {
          color = newColor;
        },);

    // Tap the button to open the picker
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Check if the bottom sheet is displayed
    expect(find.byType(ActerIconPicker), findsOneWidget);

    // Test selecting a new color
    final colorPicker = find.byKey(Key('color-picker-0'));
    await tester.tap(colorPicker); // Select a color
    await tester.pumpAndSettle();

    // Verify if the selected color has been updated in the preview
    final iconPreview = find.byKey(Key('icon-preview')); // Find the icon preview
    expect(iconPreview, findsOneWidget);

    // Get the actual Icon widget and verify its color
    final iconWidget = tester.widget<Icon>(iconPreview);
    expect(iconWidget.icon, equals(ActerIcon.list.data));
    expect(iconWidget.color, equals(newColor));
  });

  testWidgets('Icon selection updates the preview',
          (WidgetTester tester) async {
        // Prepare initial color and icon
        final initialColor = Colors.blue;
        final initialIcon = ActerIcon.list;
        final newIcon = ActerIcon.pin;

        // Build the widget
        await createWidgetUnderTest(tester,
          initialColor: initialColor,
          initialIcon: initialIcon,
          onIconSelection: (color, icon) {
            icon = newIcon;
          },);

        // Tap the button to open the picker
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // Check if the bottom sheet is displayed
        expect(find.byType(ActerIconPicker), findsOneWidget);

        // Ensure widget tree is fully rendered
        await tester.pumpAndSettle();

        final iconPicker = find.byKey(Key('icon-picker-1'));
        await tester.tap(iconPicker); // Select a new icon
        await tester.pumpAndSettle();

        // Verify if the selected color has been updated in the preview
        final iconPreview = find.byKey(Key('icon-preview')); // Find the icon preview
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
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Check if the bottom sheet is displayed
    expect(find.byType(ActerIconPicker), findsOneWidget);

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
  });
}
