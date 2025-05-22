import 'dart:ui';

import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/message_actions_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_selector.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('Message Actions Dialog Content Tests', () {
    const String testRoomId = 'test_room_id';
    const String myUserId = '@me:example.com';
    const String otherUserId = '@other:example.com';

    // Keys for testing
    const testContentKey = Key('test-message-actions-content');

    // Test message content variations
    const String shortMessage = 'Hi!';
    const String mediumMessage =
        'This is a medium length message that spans multiple words and provides a good example of typical chat content.';
    const String longMessage =
        'This is a very long message that contains a lot of text and will likely span multiple lines in the chat interface. It includes various words and phrases to simulate real conversation content that users might type in a chat application. This message is intentionally verbose to test how the message actions dialog handles longer text content and ensures the UI remains functional and visually appealing even with extensive message content.';

    Widget buildScaffoldTestWidget(
      Widget messageWidget,
      MockTimelineEventItem mockItem,
      bool isMe,
    ) {
      // this layout is used to test the message actions widget in a real chat context.
      return Scaffold(
        body: SizedBox(
          height: 800,
          width: 800,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
              Center(
                child: Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    SizedBox(width: isMe ? 0 : 36),
                    Column(
                      key: testContentKey,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        ReactionSelector(
                          isMe: isMe,
                          messageId: mockItem.mockEventId!,
                          roomId: testRoomId,
                        ),
                        messageWidget,
                        MessageActionsWidget(
                          isMe: isMe,
                          canRedact: true,
                          item: mockItem,
                          messageId: mockItem.mockEventId!,
                          roomId: testRoomId,
                        ),
                      ],
                    ),
                    SizedBox(width: isMe ? 36 : 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('Message actions widget - own short message', (tester) async {
      await loadTestFonts();

      final mockItem = MockTimelineEventItem(
        mockEventId: 'short_msg_1',
        mockSenderId: myUserId,
        mockMsgContent: MockMsgContent(mockBody: shortMessage),
      );

      final messageWidget = MessageEventItem(
        isFirstMessageBySender: true,
        isLastMessageBySender: true,
        isLastMessage: true,
        roomId: testRoomId,
        messageId: 'short_msg_1',
        item: mockItem,
        isMe: true,
        canRedact: true,
        isDM: false,
      );

      await tester.pumpProviderWidget(
        overrides: [],
        child: buildScaffoldTestWidget(messageWidget, mockItem, true),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(testContentKey),
        matchesGoldenFile('goldens/message_actions_own_short_message.png'),
      );
    });

    testWidgets('Message actions widget - own medium message', (tester) async {
      await loadTestFonts();

      final mockItem = MockTimelineEventItem(
        mockEventId: 'medium_msg_1',
        mockSenderId: myUserId,
        mockMsgContent: MockMsgContent(mockBody: mediumMessage),
      );

      final messageWidget = MessageEventItem(
        roomId: testRoomId,
        messageId: 'medium_msg_1',
        item: mockItem,
        isMe: true,
        canRedact: true,
        isDM: false,
        isFirstMessageBySender: true,
        isLastMessageBySender: true,
        isLastMessage: true,
      );

      await tester.pumpProviderWidget(
        overrides: [],
        child: buildScaffoldTestWidget(messageWidget, mockItem, true),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(testContentKey),
        matchesGoldenFile('goldens/message_actions_own_medium_message.png'),
      );
    });

    testWidgets('Message actions widget - own long message', (tester) async {
      await loadTestFonts();

      final mockItem = MockTimelineEventItem(
        mockEventId: 'long_msg_1',
        mockSenderId: myUserId,
        mockMsgContent: MockMsgContent(mockBody: longMessage),
      );

      final messageWidget = MessageEventItem(
        roomId: testRoomId,
        messageId: 'long_msg_1',
        item: mockItem,
        isMe: true,
        canRedact: true,
        isDM: false,
        isFirstMessageBySender: true,
        isLastMessageBySender: true,
        isLastMessage: true,
      );

      await tester.pumpProviderWidget(
        overrides: [],
        child: buildScaffoldTestWidget(messageWidget, mockItem, true),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(testContentKey),
        matchesGoldenFile('goldens/message_actions_own_long_message.png'),
      );
    });

    testWidgets('Message actions widget - other user short message', (
      tester,
    ) async {
      await loadTestFonts();

      final mockItem = MockTimelineEventItem(
        mockEventId: 'other_short_msg_1',
        mockSenderId: otherUserId,
        mockMsgContent: MockMsgContent(mockBody: shortMessage),
      );

      final messageWidget = MessageEventItem(
        roomId: testRoomId,
        messageId: 'other_short_msg_1',
        item: mockItem,
        isMe: false,
        canRedact: false,
        isDM: false,
        isFirstMessageBySender: true,
        isLastMessageBySender: true,
        isLastMessage: true,
      );

      await tester.pumpProviderWidget(
        overrides: [],
        child: buildScaffoldTestWidget(messageWidget, mockItem, false),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(testContentKey),
        matchesGoldenFile('goldens/message_actions_other_short_message.png'),
      );
    });

    testWidgets('Message actions widget - other user medium message', (
      tester,
    ) async {
      await loadTestFonts();

      final mockItem = MockTimelineEventItem(
        mockEventId: 'other_medium_msg_1',
        mockSenderId: otherUserId,
        mockMsgContent: MockMsgContent(mockBody: mediumMessage),
      );

      final messageWidget = MessageEventItem(
        roomId: testRoomId,
        messageId: 'other_medium_msg_1',
        item: mockItem,
        isMe: false,
        canRedact: false,
        isDM: false,
        isFirstMessageBySender: true,
        isLastMessageBySender: true,
        isLastMessage: true,
      );

      await tester.pumpProviderWidget(
        overrides: [],
        child: buildScaffoldTestWidget(messageWidget, mockItem, false),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(testContentKey),
        matchesGoldenFile('goldens/message_actions_other_medium_message.png'),
      );
    });

    testWidgets('Message actions widget - other user long message', (
      tester,
    ) async {
      await loadTestFonts();

      final mockItem = MockTimelineEventItem(
        mockEventId: 'other_long_msg_1',
        mockSenderId: otherUserId,
        mockMsgContent: MockMsgContent(mockBody: longMessage),
      );

      final messageWidget = MessageEventItem(
        roomId: testRoomId,
        messageId: 'other_long_msg_1',
        item: mockItem,
        isMe: false,
        canRedact: false,
        isDM: false,
        isFirstMessageBySender: true,
        isLastMessageBySender: true,
        isLastMessage: true,
      );

      await tester.pumpProviderWidget(
        overrides: [],
        child: buildScaffoldTestWidget(messageWidget, mockItem, false),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(testContentKey),
        matchesGoldenFile('goldens/message_actions_other_long_message.png'),
      );
    });
  });
}
