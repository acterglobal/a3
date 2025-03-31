import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/invitationAccepted.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/invitationRevoked.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/invited.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/joined.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_membership_change.dart';

void main() {
  testWidgets('Invitation revoked of user', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.invitationRevoked.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockMembershipChange: MockMembershipChange(
        mockDisplayName: 'user-display-name',
      ),
    );
    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityInvitationRevokedItemWidget(activity: mockActivity),
      ),
    );

    // Verify the change text is displayed
    expect(find.text('Declined Invitation of'), findsOneWidget);
    // Verify the icon is displayed
    expect(find.byIcon(Icons.person_remove), findsOneWidget);
  });

  testWidgets('Invitation accepted of user', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.invitationAccepted.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockMembershipChange: MockMembershipChange(
        mockDisplayName: 'user-display-name',
      ),
    );
    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityInvitationAcceptedItemWidget(activity: mockActivity),
      ),
    );

    // Verify the change text is displayed
    expect(find.text('Accepted Invitation of'), findsOneWidget);
    // Verify the icon is displayed
    expect(find.byIcon(Icons.person_add), findsOneWidget);
  });

  
  testWidgets('user joined room', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.joined.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockMembershipChange: MockMembershipChange(
        mockDisplayName: 'user-display-name',
      ),
    );
    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityJoinedItemWidget(activity: mockActivity),
      ),
    );

    // Verify the change text is displayed
    expect(find.text('Joined'), findsOneWidget);
    // Verify the icon is displayed
    expect(find.byIcon(Icons.people_sharp), findsOneWidget);
  });

   testWidgets('invited user to room', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.invited.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockMembershipChange: MockMembershipChange(
        mockDisplayName: 'user-display-name',
      ),
    );
    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityInvitedItemWidget(activity: mockActivity),
      ),
    );

    // Verify the change text is displayed
    expect(find.text('Invited'), findsOneWidget);
    // Verify the icon is displayed
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
  });
}
