import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/activities/widgets/security_privacy_widget.dart';

void main() {
  Future<void> pumpSecurityWidget(
    WidgetTester tester, {
    IconData? icon,
    Color? iconColor,
    String? title,
    String? subtitle,
    List<Widget>? actions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SecurityPrivacyWidget(
              icon: icon ?? Icons.security,
              iconColor: iconColor,
              title: title ?? 'Test Title',
              subtitle: subtitle ?? 'Test Subtitle',
              actions: actions ?? const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SecurityPrivacyWidget', () {
    testWidgets('renders all basic components correctly', (tester) async {
      await pumpSecurityWidget(tester);

      // Verify basic structure
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders with custom icon color', (tester) async {
      const customColor = Colors.blue;
      await pumpSecurityWidget(tester, iconColor: customColor);

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.color, equals(customColor));
    });

    testWidgets('renders actions when provided', (tester) async {
      final testActions = [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Action 1'),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Action 2'),
        ),
      ];

      await pumpSecurityWidget(tester, actions: testActions);

      expect(find.text('Action 1'), findsOneWidget);
      expect(find.text('Action 2'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('handles long subtitle text correctly', (tester) async {
      final longSubtitle = 'A' * 200; // Very long text
      await pumpSecurityWidget(tester, subtitle: longSubtitle);

      expect(find.text(longSubtitle), findsOneWidget);
      // Verify it's wrapped with the correct key
      expect(find.byKey(const Key('subtitle-key')), findsOneWidget);
    });
  });
}