import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_membership_container_widget.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_membership_change.dart';

void main() {
  group('ActivityMembershipItemWidget Tests', () {
    testWidgets('User joined room', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.joined.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'joined',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.people_sharp), findsOneWidget);
      expect(find.textContaining('joined'), findsOneWidget);
    });

    testWidgets('User left room', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.left.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'left',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
    });

    testWidgets('Invitation accepted', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.invitationAccepted.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'invitationAccepted',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.textContaining('accepted'), findsOneWidget);
    });

    testWidgets('Invitation rejected', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.invitationRejected.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'invitationRejected',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_off), findsOneWidget);
      expect(find.textContaining('rejected'), findsOneWidget);
    });

    testWidgets('Invitation revoked', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.invitationRevoked.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'invitationRevoked',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_remove), findsOneWidget);
      expect(find.textContaining('revoked'), findsOneWidget);
    });

    testWidgets('Knock accepted', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.knockAccepted.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'knockAccepted',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.textContaining('accepted'), findsOneWidget);
    });

    testWidgets('Knock retracted', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.knockRetracted.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'knockRetracted',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_remove), findsOneWidget);
      expect(find.textContaining('retracted'), findsOneWidget);
    });

    testWidgets('Knock denied', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.knockDenied.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'knockDenied',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.textContaining('denied'), findsOneWidget);
    });

    testWidgets('User banned', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.banned.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'banned',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.textContaining('banned'), findsOneWidget);
    });

    testWidgets('User unbanned', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.unbanned.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'unbanned',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.block_flipped), findsOneWidget);
      expect(find.textContaining('unbanned'), findsOneWidget);
    });

    testWidgets('User kicked', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.kicked.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'kicked',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_remove), findsOneWidget);
      expect(find.textContaining('kicked'), findsOneWidget);
    });

    testWidgets('User invited', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.invited.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'invited',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.textContaining('invited'), findsOneWidget);
    });

    testWidgets('User kicked and banned', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.kickedAndBanned.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'kickedAndBanned',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.textContaining('kicked and banned'), findsOneWidget);
    });

    testWidgets('User knocked', (tester) async {
      final mockActivity = MockActivity(
        mockType: PushStyles.knocked.name,
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'knocked',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.textContaining('knocked'), findsOneWidget);
    });

    testWidgets('Unknown membership change', (tester) async {
      final mockActivity = MockActivity(
        mockType: 'unknown',
        mockRoomId: 'room-id',
        mockSenderId: 'sender-id',
        mockMembershipContent: MockMembershipContent(
          mockUserId: 'user-id',
          mockChange: 'unknown',
        ),
      );
      await tester.pumpProviderWidget(
        child: Material(
          child: ActivityMembershipItemWidget(activity: mockActivity),
        ),
      );
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.textContaining('unknown'), findsOneWidget);
    });
  });
}
