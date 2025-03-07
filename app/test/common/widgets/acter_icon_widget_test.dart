import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest({
    double? iconSize,
    Color? color,
    ActerIcon? icon,
    Function(Color, ActerIcon)? onIconSelection,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ActerIconWidget(
          iconSize: iconSize,
          color: color,
          icon: icon,
          onIconSelection: onIconSelection,
        ),
      ),
    );
  }

  testWidgets('ActerIconWidget renders icon and color correctly', (
    WidgetTester tester,
  ) async {
    // Build the widget using the helper function
    await tester.pumpWidget(
      createWidgetUnderTest(
        iconSize: 50,
        color: Colors.red,
        icon: ActerIcon.car,
      ),
    );

    // Verify if the icon and color are rendered correctly
    expect(find.byType(Icon), findsOneWidget);
    expect((tester.widget(find.byType(Icon)) as Icon).size, 50);
    expect((tester.widget(find.byType(Icon)) as Icon).color, Colors.red);
    expect((tester.widget(find.byType(Icon)) as Icon).icon, ActerIcon.car.data);
  });

  testWidgets(
    'ActerIconWidget renders default values when no values are passed',
    (WidgetTester tester) async {
      // Build the widget using the helper function without iconSize and color
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify if the icon and color are rendered with default values
      expect(find.byType(Icon), findsOneWidget);
      expect(
        (tester.widget(find.byType(Icon)) as Icon).size,
        70,
      ); // Default size
      expect(
        (tester.widget(find.byType(Icon)) as Icon).color,
        Colors.grey,
      ); // Default color
      expect(
        (tester.widget(find.byType(Icon)) as Icon).icon,
        ActerIcon.list.data,
      ); // Default icon
    },
  );
}
