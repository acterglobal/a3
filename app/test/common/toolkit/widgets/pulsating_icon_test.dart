import 'package:acter/common/toolkit/widgets/pulsating_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PulsatingIcon', () {
    testWidgets('renders correctly with required props', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PulsatingIcon(icon: Icons.check, color: Colors.blue),
          ),
        ),
      );

      expect(find.byType(PulsatingIcon), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('uses custom size', (tester) async {
      const customSize = 24.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PulsatingIcon(
              icon: Icons.check,
              color: Colors.blue,
              size: customSize,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check));
      expect(icon.size, equals(customSize));
    });

    testWidgets('uses custom duration', (tester) async {
      const customDuration = Duration(milliseconds: 500);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PulsatingIcon(
              icon: Icons.check,
              color: Colors.blue,
              duration: customDuration,
            ),
          ),
        ),
      );

      // Find AnimatedBuilder that's a descendant of PulsatingIcon
      expect(
        find.descendant(
          of: find.byType(PulsatingIcon),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );

      // Verify animation doesn't crash with custom duration
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('animation runs and changes scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PulsatingIcon(icon: Icons.check, color: Colors.blue),
          ),
        ),
      );

      // Find the Transform widget within PulsatingIcon
      final transformFinder = find.descendant(
        of: find.byType(PulsatingIcon),
        matching: find.byType(Transform),
      );

      // Get initial transform
      final initialTransform = tester.widget<Transform>(transformFinder);
      final initialScale = initialTransform.transform.getMaxScaleOnAxis();

      // Wait for animation to progress
      await tester.pump(const Duration(milliseconds: 500));

      // Get updated transform
      final updatedTransform = tester.widget<Transform>(transformFinder);
      final updatedScale = updatedTransform.transform.getMaxScaleOnAxis();

      // Scale should be different (animation is working)
      expect(initialScale, isNot(equals(updatedScale)));
    });
  });
}
