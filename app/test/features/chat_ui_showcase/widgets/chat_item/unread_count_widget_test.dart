import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/unread_count_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('UnreadCountWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      int notifications = 0,
      int mentions = 0,
      int messages = 0,
      bool isFeatureActive = true,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          isActiveProvider(
            LabsFeature.chatUnread,
          ).overrideWith((ref) => isFeatureActive),
          unreadCountersProvider.overrideWith(
            (ref, roomId) => Future.value((notifications, mentions, messages)),
          ),
        ],
        child: const UnreadCountWidget(roomId: 'mock-room-1'),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show nothing when no unread notifications', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(UnreadCountWidget),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });

    testWidgets('should show nothing when feature is inactive', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        notifications: 5,
        isFeatureActive: false,
      );
      expect(find.byType(SizedBox), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(UnreadCountWidget),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });

    testWidgets('should show unread count when there are notifications', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, notifications: 5);
      expect(
        find.descendant(
          of: find.byType(UnreadCountWidget),
          matching: find.byType(Container),
        ),
        findsOneWidget,
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should not show unread count when there are only mentions', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, mentions: 3);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(UnreadCountWidget),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });

    testWidgets('should not show unread count when there are only messages', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, messages: 7);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(UnreadCountWidget),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });

    testWidgets('should use correct styling for unread count', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, notifications: 5);

      // Find the Container with the unread count
      final containerFinder = find.descendant(
        of: find.byType(UnreadCountWidget),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder);

      // Check container styling
      expect(container.margin, equals(const EdgeInsets.only(left: 4)));
      expect(
        container.padding,
        equals(const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
      );

      // Check decoration
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(100)));

      // Get the theme from the context of the UnreadCountWidget
      final theme = Theme.of(tester.element(find.byType(UnreadCountWidget)));
      expect(decoration.color, equals(theme.colorScheme.primary));

      // Check text style
      final text = container.child as Text;
      expect(text.style, equals(theme.textTheme.bodySmall));
    });
  });
}
