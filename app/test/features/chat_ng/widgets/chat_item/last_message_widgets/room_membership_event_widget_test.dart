import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/room_membership_event_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('RoomMembershipEventWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required String roomId,
      required String myUserId,
      required MockTimelineEventItem mockEventItem,
    }) async {
      final senderUserId = mockEventItem.sender().toString();
      final contentUserId =
          mockEventItem.membershipContent()?.userId().toString() ?? '';

      await tester.pumpProviderWidget(
        overrides: [
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: senderUserId,
          )),
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: contentUserId,
          )),
          myUserIdStrProvider.overrideWith((ref) => myUserId),
        ],
        child: RoomMembershipEventWidget(
          roomId: roomId,
          eventItem: mockEventItem,
        ),
      );
    }

    testWidgets('should show nothing when membership content is null', (
      WidgetTester tester,
    ) async {
      final mockEventItem = MockTimelineEventItem(mockMembershipContent: null);

      await tester.pumpProviderWidget(
        child: RoomMembershipEventWidget(roomId: '', eventItem: mockEventItem),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    group('Member changes with 2 cases', () {
      testWidgets('Joined message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventjoinedRoom22
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('david joined the room.'), findsOneWidget);
      });

      testWidgets('Left message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventLeftRoom23
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('david left the room.'), findsOneWidget);
      });

      testWidgets('Invitation accepted message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventInvitationAcceptedRoom24
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david accepted the invite.'),
          findsOneWidget,
        );
      });

      testWidgets('Invitation rejected message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventInvitationRejectedRoom25
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david rejected the invite.'),
          findsOneWidget,
        );
      });

      testWidgets('Invitation revoked message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventInvitationRevokedRoom26
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david had their invite revoked.'),
          findsOneWidget,
        );
      });

      testWidgets('Knock accepted message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKnockAcceptedRoom27
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david had their knock accepted.'),
          findsOneWidget,
        );
      });

      testWidgets('Knock retracted message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKnockRetractedRoom28
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david retracted their knock.'),
          findsOneWidget,
        );
      });

      testWidgets('Knock denied message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKnockDeniedRoom29
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david had their knock denied.'),
          findsOneWidget,
        );
      });
    });

    group('Member changes with 3 cases', () {
      testWidgets('Banned message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventBannedRoom30
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('emily banned david.'), findsOneWidget);
      });

      testWidgets('Unbanned message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventUnbannedRoom31
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('emily unbanned david.'), findsOneWidget);
      });

      testWidgets('Kicked message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKickedRoom32
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('emily kicked david.'), findsOneWidget);
      });

      testWidgets('Invited message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventInvitedRoom33
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('emily invited david.'), findsOneWidget);
      });

      testWidgets('Kicked and banned message', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKickedAndBannedRoom34
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('emily kicked and banned david.'),
          findsOneWidget,
        );
      });
    });
  });
}
