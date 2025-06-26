import 'package:acter/common/widgets/dashed_line_vertical.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest({
    double? height,
    double? dashHeight,
    double? dashSpacing,
    Color? color,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashedLineVertical(
          height: height,
          dashHeight: dashHeight ?? 6,
          dashSpacing: dashSpacing ?? 5,
          color: color ?? Colors.grey,
        ),
      ),
    );
  }

  group('DashedLineVertical Widget Tests', () {
    testWidgets('renders with default values', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify the widget is rendered
      expect(find.byType(DashedLineVertical), findsOneWidget);
      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(SizedBox),
      ), findsOneWidget);

      // Verify default SizedBox dimensions
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 0.5);
      expect(sizedBox.height, isNull); // height is null by default
    });

    testWidgets('renders with custom height', (WidgetTester tester) async {
      const customHeight = 100.0;
      await tester.pumpWidget(createWidgetUnderTest(height: customHeight));

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, customHeight);
    });

    testWidgets('renders with custom dash height', (WidgetTester tester) async {
      const customDashHeight = 10.0;
      await tester.pumpWidget(createWidgetUnderTest(dashHeight: customDashHeight));

      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
      // Verify the CustomPaint is rendered with the correct painter
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('renders with custom dash spacing', (WidgetTester tester) async {
      const customDashSpacing = 8.0;
      await tester.pumpWidget(createWidgetUnderTest(dashSpacing: customDashSpacing));

      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
      // Verify the CustomPaint is rendered with the correct painter
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('renders with custom color', (WidgetTester tester) async {
      const customColor = Colors.red;
      await tester.pumpWidget(createWidgetUnderTest(color: customColor));

      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
      // Verify the CustomPaint is rendered with the correct painter
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('renders with all custom properties', (WidgetTester tester) async {
      const customHeight = 200.0;
      const customDashHeight = 12.0;
      const customDashSpacing = 6.0;
      const customColor = Colors.blue;

      await tester.pumpWidget(createWidgetUnderTest(
        height: customHeight,
        dashHeight: customDashHeight,
        dashSpacing: customDashSpacing,
        color: customColor,
      ));

      // Verify SizedBox properties
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 0.5);
      expect(sizedBox.height, customHeight);

      // Verify CustomPaint is rendered
      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('maintains consistent width of 0.5', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 0.5);
    });

    testWidgets('CustomPaint painter is not null', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);
    });
  });

  group('Integration Tests', () {
    testWidgets('widget rebuilds correctly when properties change', (WidgetTester tester) async {
      // Initial render
      await tester.pumpWidget(createWidgetUnderTest(
        height: 100,
        color: Colors.grey,
      ));

      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Change properties and rebuild
      await tester.pumpWidget(createWidgetUnderTest(
        height: 150,
        color: Colors.blue,
        dashHeight: 8,
        dashSpacing: 6,
      ));

      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Verify the new properties are applied
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 150);

      // Verify CustomPaint is still rendered
      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DashedLineVertical),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);
    });

    testWidgets('widget works in different container contexts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const DashedLineVertical(height: 50),
                const SizedBox(height: 20),
                const DashedLineVertical(height: 100, color: Colors.red),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(DashedLineVertical), findsNWidgets(2));
      expect(find.descendant(
        of: find.byType(DashedLineVertical),
        matching: find.byType(CustomPaint),
      ), findsNWidgets(2));
    });

    testWidgets('widget handles edge cases', (WidgetTester tester) async {
      // Test with zero height
      await tester.pumpWidget(createWidgetUnderTest(height: 0));
      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Test with very small height
      await tester.pumpWidget(createWidgetUnderTest(height: 1));
      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Test with very large height
      await tester.pumpWidget(createWidgetUnderTest(height: 1000));
      expect(find.byType(DashedLineVertical), findsOneWidget);
    });

    testWidgets('widget handles different dash configurations', (WidgetTester tester) async {
      // Test with very small dash height
      await tester.pumpWidget(createWidgetUnderTest(dashHeight: 1));
      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Test with very large dash height
      await tester.pumpWidget(createWidgetUnderTest(dashHeight: 50));
      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Test with zero dash spacing
      await tester.pumpWidget(createWidgetUnderTest(dashSpacing: 0));
      expect(find.byType(DashedLineVertical), findsOneWidget);

      // Test with large dash spacing
      await tester.pumpWidget(createWidgetUnderTest(dashSpacing: 20));
      expect(find.byType(DashedLineVertical), findsOneWidget);
    });
  });
} 