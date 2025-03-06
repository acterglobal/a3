import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/comment.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../../comments/mock_data/mock_message_content.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    MockActivity? mockActivity,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) => MockAvatarInfo(
            uniqueId: param.userId,
            mockDisplayName: 'User-1',
          ),
        ),
      ],
      child: Material(
        child: ActivityCommentItemWidget(activity: mockActivity!),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('Comment on Pin Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.comment.name,
      mockMsgContent: MockMsgContent(
        bodyText: 'This is a comment on a pin object',
      ),
      mockObject: MockActivityObject(
        mockType: SpaceObjectTypes.pin.name,
        mockEmoji: SpaceObjectTypes.pin.emoji,
        mockTitle: 'Pin Name',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action title
    expect(
      find.text('${PushStyles.comment.emoji} Commented on'),
      findsOneWidget,
    );

    // Verify object info
    expect(find.text('${SpaceObjectTypes.pin.emoji} Pin Name'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify comment content
    expect(find.text('This is a comment on a pin object'), findsOneWidget);
  });
}
