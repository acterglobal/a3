import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/events/room_membership_event_widget.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/membership_usecases.dart';
import 'package:acter/l10n/generated/l10n.dart';
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
          )).overrideWith((ref) => senderUserId),
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: contentUserId,
          )).overrideWith((ref) => contentUserId),
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
      testWidgets('Joined message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventjoinedRoom22
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipYouJoined),
          findsOneWidget,
        );
      });

      testWidgets('Joined message - Other', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventjoinedRoom22
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipOtherJoined(contentUserId)),
          findsOneWidget,
        );
      });

      testWidgets('Left message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventLeftRoom23
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(find.textContaining(lang.chatMembershipYouLeft), findsOneWidget);
      });

      testWidgets('Left message - Other', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventLeftRoom23
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipOtherLeft(contentUserId)),
          findsOneWidget,
        );
      });

      testWidgets('Invitation accepted message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitationAcceptedRoom24
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipInvitationYouAccepted),
          findsOneWidget,
        );
      });

      testWidgets('Invitation accepted message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitationAcceptedRoom24
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipInvitationOtherAccepted(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Invitation rejected message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitationRejectedRoom25
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipInvitationYouRejected),
          findsOneWidget,
        );
      });

      testWidgets('Invitation rejected message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitationRejectedRoom25
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipInvitationOtherRejected(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Invitation revoked message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitationRevokedRoom26
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipInvitationYouRevoked),
          findsOneWidget,
        );
      });

      testWidgets('Invitation revoked message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitationRevokedRoom26
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipInvitationOtherRevoked(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Knock accepted message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKnockAcceptedRoom27
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipKnockYouAccepted),
          findsOneWidget,
        );
      });

      testWidgets('Knock accepted message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKnockAcceptedRoom27
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipKnockOtherAccepted(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Knock retracted message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKnockRetractedRoom28
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipKnockYouRetracted),
          findsOneWidget,
        );
      });

      testWidgets('Knock retracted message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKnockRetractedRoom28
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipKnockOtherRetracted(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Knock denied message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKnockDeniedRoom29
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: senderId,
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipKnockYouDenied),
          findsOneWidget,
        );
      });

      testWidgets('Knock denied message - Other', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKnockDeniedRoom29
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipKnockOtherDenied(contentUserId),
          ),
          findsOneWidget,
        );
      });
    });

    group('Member changes with 3 cases', () {
      testWidgets('Banned message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventBannedRoom30
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: mockEventItemData.sender().toString(),
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipYouBannedOther(contentUserId)),
          findsOneWidget,
        );
      });

      testWidgets('Banned message - On me', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventBannedRoom30
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId:
              mockEventItemData.membershipContent()?.userId().toString() ?? '',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipOtherBannedYou(senderId)),
          findsOneWidget,
        );
      });

      testWidgets('Banned message - Other banned other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventBannedRoom30
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();
        final contentUserId =
            mockEventItemData.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipOtherBannedOther(senderId, contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Unbanned message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventUnbannedRoom31
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: mockEventItemData.sender().toString(),
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipYouUnbannedOther(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Unbanned message - On me', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventUnbannedRoom31
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId:
              mockEventItemData.membershipContent()?.userId().toString() ?? '',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipOtherUnbannedYou(senderId)),
          findsOneWidget,
        );
      });

      testWidgets('Unbanned message - Other unbanned other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventUnbannedRoom31
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();
        final contentUserId =
            mockEventItemData.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipOtherUnbannedOther(senderId, contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Kicked message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKickedRoom32
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: mockEventItemData.sender().toString(),
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipYouKickedOther(contentUserId)),
          findsOneWidget,
        );
      });

      testWidgets('Kicked message - On me', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventKickedRoom32
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId:
              mockEventItemData.membershipContent()?.userId().toString() ?? '',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipOtherKickedYou(senderId)),
          findsOneWidget,
        );
      });

      testWidgets('Kicked message - Other kicked other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKickedRoom32
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();
        final contentUserId =
            mockEventItemData.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipOtherKickedOther(senderId, contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Invited message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventInvitedRoom33
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: mockEventItemData.sender().toString(),
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipYouInvitedOther(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Invited message - On me', (WidgetTester tester) async {
        final mockEventItemData =
            membershipEventInvitedRoom33
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId:
              mockEventItemData.membershipContent()?.userId().toString() ?? '',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(lang.chatMembershipOtherInvitedYou(senderId)),
          findsOneWidget,
        );
      });

      testWidgets('Invited message - Other invited other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventInvitedRoom33
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();
        final contentUserId =
            mockEventItemData.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipOtherInvitedOther(senderId, contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Kicked and banned message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKickedAndBannedRoom34
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final contentUserId =
            mockEventItemData!.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: mockEventItemData.sender().toString(),
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipYouKickedAndBannedOther(contentUserId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Kicked and banned message - On me', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKickedAndBannedRoom34
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId:
              mockEventItemData.membershipContent()?.userId().toString() ?? '',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipOtherKickedAndBannedYou(senderId),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Kicked and banned message - Other kicked and banned other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            membershipEventKickedAndBannedRoom34
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;
        final senderId = mockEventItemData!.sender().toString();
        final contentUserId =
            mockEventItemData.membershipContent()?.userId().toString() ?? '';

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(RoomMembershipEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatMembershipOtherKickedAndBannedOther(
              senderId,
              contentUserId,
            ),
          ),
          findsOneWidget,
        );
      });
    });
  });
}
