import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/room_message_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/room_membership_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/text_message_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/general_message_event_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/mock_chat_providers.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('LastMessageWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      MockTimelineItem? mockTimelineItem,
      bool isError = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
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

    testWidgets(
      'should show RoomMessageEventWidget for m.room.message events',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          mockTimelineItem: MockTimelineItem(
            mockTimelineEventItem: MockTimelineEventItem(
              mockEventType: 'm.room.message',
              mockMsgContent: MockMsgContent(mockBody: 'Test message'),
            ),
          ),
        );
        expect(find.byType(RoomMessageEventWidget), findsOneWidget);
      },
    );

    testWidgets(
      'should show RoomMembershipEventWidget for MembershipChange events',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          mockTimelineItem: MockTimelineItem(
            mockTimelineEventItem: MockTimelineEventItem(
              mockEventType: 'MembershipChange',
            ),
          ),
        );
        expect(find.byType(RoomMembershipEventWidget), findsOneWidget);
      },
    );

    testWidgets(
      'should show ProfileChangesEventWidget for ProfileChange events',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          mockTimelineItem: MockTimelineItem(
            mockTimelineEventItem: MockTimelineEventItem(
              mockEventType: 'ProfileChange',
            ),
          ),
        );
        expect(find.byType(ProfileChangesEventWidget), findsOneWidget);
      },
    );

    testWidgets('should show TextMessageWidget for m.room.encrypted events', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.encrypted',
          ),
        ),
      );
      expect(find.byType(TextMessageWidget), findsOneWidget);
    });

    testWidgets('should show TextMessageWidget for m.room.redaction events', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: MockTimelineEventItem(
            mockEventType: 'm.room.redaction',
          ),
        ),
      );
      expect(find.byType(TextMessageWidget), findsOneWidget);
    });

    testWidgets(
      'should show GeneralMessageEventWidget for unknown event types',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          mockTimelineItem: MockTimelineItem(
            mockTimelineEventItem: MockTimelineEventItem(
              mockEventType: 'unknown.event.type',
            ),
          ),
        );
        expect(find.byType(GeneralMessageEventWidget), findsOneWidget);
      },
    );

    testWidgets('should handle error case', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isError: true);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should show nothing when eventItem is null', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        mockTimelineItem: MockTimelineItem(mockTimelineEventItem: null),
      );
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
