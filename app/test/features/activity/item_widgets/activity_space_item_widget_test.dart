import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomAvatar.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomName.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomTopic.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';

void main() {
  testWidgets('Room name update', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.roomName.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockObject: MockActivityObject(mockType: 'roomName'),
    );

    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityRoomNameItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();

    // Verify the change text is displayed
    expect(find.textContaining('changed the room name'), findsOneWidget);

    // Verify icon is present
    expect(find.byIcon(PhosphorIconsRegular.pencilSimpleLine), findsOneWidget);
  });

  testWidgets('Room topic update', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.roomTopic.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockObject: MockActivityObject(mockType: 'roomTopic'),
    );

    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityRoomTopicItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();

    // Verify the change text is displayed
    expect(find.textContaining('changed the room topic'), findsOneWidget);

    // Verify icon is present
    expect(find.byIcon(PhosphorIconsRegular.pencilSimpleLine), findsOneWidget);
  });

  testWidgets('Room avatar update', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.roomAvatar.name,
      mockRoomId: 'room-id',
      mockSenderId: 'sender-id',
      mockObject: MockActivityObject(mockType: 'roomAvatar'),
    );

    await tester.pumpProviderWidget(
      child: Material(
        child: ActivityRoomAvatarItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
    // Verify the avatar is displayed
    expect(find.byType(ActerAvatar), findsOneWidget);
    // Verify the change text is displayed
    expect(find.textContaining('changed the room avatar url'), findsOneWidget);
  });
}
