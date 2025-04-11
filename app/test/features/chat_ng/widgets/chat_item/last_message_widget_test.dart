import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/mock_chat_providers.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('LastMessageWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      MockTimelineItem? mockTimelineItem,
      bool isUnread = false,
      bool isFeatureActive = true,
      bool isDM = false,
      bool isError = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasUnreadMessages.overrideWith((ref, roomId) => isUnread),
          isActiveProvider(
            LabsFeature.chatUnread,
          ).overrideWith((ref) => isFeatureActive),
          isDirectChatProvider.overrideWith((ref, roomId) => isDM),
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
        child: const LastMessageWidget(roomId: 'mock-room-1'),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show message content when available', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: 'Test message'),
          ),
        ),
      );
      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), equals('Test message'));
    });

    testWidgets('should show sender name for non-DM rooms', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: 'Test message'),
            mockSenderId: '@user123:example.com',
          ),
        ),
        isDM: false,
      );
      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), equals('User123 : Test message'));
    });

    testWidgets('should not show sender name for DM rooms', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: 'Test message'),
            mockSenderId: '@user123:example.com',
          ),
        ),
        isDM: true,
      );
      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), equals('Test message'));
    });

    testWidgets('should use correct color for unread messages', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: 'Test message'),
          ),
        ),
        isUnread: true,
        isFeatureActive: true,
      );
      final richText = tester.widget<RichText>(find.byType(RichText));
      final theme = Theme.of(tester.element(find.byType(RichText)));

      // Get the TextSpan from the RichText
      final textSpan = richText.text as TextSpan;

      // Get the last child (the message text span)
      final messageSpan = textSpan.children!.last as TextSpan;

      // Check the color of the message text span
      expect(messageSpan.style?.color, equals(theme.colorScheme.onSurface));
    });

    testWidgets('should use correct color for read messages', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: 'Test message'),
          ),
        ),
        isUnread: false,
        isFeatureActive: true,
      );
      final richText = tester.widget<RichText>(find.byType(RichText));
      final theme = Theme.of(tester.element(find.byType(RichText)));

      // Get the TextSpan from the RichText
      final textSpan = richText.text as TextSpan;

      // Get the last child (the message text span)
      final messageSpan = textSpan.children!.last as TextSpan;

      // Check the color of the message text span
      expect(messageSpan.style?.color, equals(theme.colorScheme.surfaceTint));
    });

    testWidgets('should handle empty messages', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: ''),
          ),
        ),
      );
      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), equals(''));
    });

    testWidgets('should not show unread state when feature is inactive', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.message',
            mockMsgContent: MockMsgContent(mockBody: 'Test message'),
          ),
        ),
        isUnread: true,
        isFeatureActive: false,
      );
      final richText = tester.widget<RichText>(find.byType(RichText));
      final theme = Theme.of(tester.element(find.byType(RichText)));

      // Get the TextSpan from the RichText
      final textSpan = richText.text as TextSpan;

      // Get the last child (the message text span)
      final messageSpan = textSpan.children!.last as TextSpan;

      // Check the color of the message text span
      expect(messageSpan.style?.color, equals(theme.colorScheme.surfaceTint));
    });

    testWidgets('should handle error case', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isError: true);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
