import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_time_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/mock_chat_providers.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('LastMessageTimeWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      MockTimelineItem? mockTimelineItem,
      bool isUnread = false,
      bool isFeatureActive = true,
      bool isError = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasUnreadMessages.overrideWith((ref, roomId) => isUnread),
          isActiveProvider(
            LabsFeature.chatUnread,
          ).overrideWith((ref) => isFeatureActive),
          latestMessageProvider.overrideWith(() {
            final notifier = MockAsyncLatestMsgNotifier(
              timelineItem: mockTimelineItem,
            );
            if (isError) {
              notifier.state = throw Exception('Error');
            }
            return notifier;
          }),
        ],
        child: const LastMessageTimeWidget(roomId: 'mock-room-1'),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show timestamp when available', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockOriginServerTs: 1700000000000,
          ),
        ),
      );
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(SizedBox), findsNothing);
    });

    testWidgets('should use correct color for unread messages', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockOriginServerTs: 1700000000000,
          ),
        ),
        isUnread: true,
        isFeatureActive: true,
      );
      final textWidget = tester.widget<Text>(find.byType(Text));
      final theme = Theme.of(tester.element(find.byType(Text)));
      expect(textWidget.style?.color, equals(theme.colorScheme.onSurface));
    });

    testWidgets('should use correct color for read messages', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockOriginServerTs: 1700000000000,
          ),
        ),
        isUnread: false,
        isFeatureActive: true,
      );
      final textWidget = tester.widget<Text>(find.byType(Text));
      final theme = Theme.of(tester.element(find.byType(Text)));
      expect(textWidget.style?.color, equals(theme.colorScheme.surfaceTint));
    });

    testWidgets('should use correct text style', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockOriginServerTs: 1700000000000,
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.byType(Text));
      final theme = Theme.of(tester.element(find.byType(Text)));
      expect(textWidget.style?.fontSize, equals(12));
      expect(
        textWidget.style?.fontFamily,
        equals(theme.textTheme.bodySmall?.fontFamily),
      );
    });

    testWidgets('should not show unread state when feature is inactive', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockOriginServerTs: 1700000000000,
          ),
        ),
        isUnread: true,
        isFeatureActive: false,
      );
      final textWidget = tester.widget<Text>(find.byType(Text));
      final theme = Theme.of(tester.element(find.byType(Text)));
      expect(textWidget.style?.color, equals(theme.colorScheme.surfaceTint));
    });

    testWidgets('should handle error case', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isError: true);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
