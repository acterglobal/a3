import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/room_message_event_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('RoomMessageEventWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required MockChatItem mockChatItem,
    }) async {
      final mockEventItem =
          mockChatItem.mockConvo.mockTimelineItem?.mockTimelineEventItem;
      if (mockEventItem == null) return;

      final senderUserId = mockEventItem.sender().toString();

      await tester.pumpProviderWidget(
        overrides: [
          lastMessageDisplayNameProvider((
            roomId: mockChatItem.roomId,
            userId: senderUserId,
          )),
          isDirectChatProvider(mockChatItem.roomId).overrideWith(
            (ref) => Future.value(mockChatItem.mockConvo.mockIsDm),
          ),
          lastMessageTextProvider(mockEventItem),
        ],
        child: RoomMessageEventWidget(
          roomId: mockChatItem.roomId,
          eventItem: mockEventItem,
        ),
      );

      // Wait for async operations to complete
      await tester.pumpAndSettle();
    }

    testWidgets('Text message', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, mockChatItem: davidDmRoom15);

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);

      final RichText richText = tester.widget(richTextFinder);
      final text = richText.text.toPlainText();
      expect(text, 'Task completed and merged to main branch.');
    });

    testWidgets('Image message', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: imageMessageDmRoom16,
      );

      expect(find.text('Image'), findsOneWidget);
    });

    testWidgets('Video message', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: videoMessageDmRoom17,
      );

      expect(find.text('david : '), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
    });

    testWidgets('Audio message', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: audioMessageDmRoom18,
      );

      expect(find.text('Audio'), findsOneWidget);
    });

    testWidgets('File message', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: fileMessageDmRoom19,
      );

      expect(find.text('File'), findsOneWidget);
    });

    testWidgets('Location message', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: locationMessageDmRoom20,
      );

      expect(find.text('michael : '), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('Unknown message type shows nothing', (
      WidgetTester tester,
    ) async {
      final mockChatItem = createMockChatItem(
        roomId: 'mock-room',
        displayName: 'Test Room',
        timelineEventItem: MockTimelineEventItem(
          mockMsgType: 'unknown',
          mockEventType: 'm.room.message',
        ),
      );

      await createWidgetUnderTest(tester: tester, mockChatItem: mockChatItem);

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
