import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity_object.dart';
import 'package:acter_notifify/model/push_styles.dart';

// Activity ID constants
final reactionEventId = 'reaction-activity-social-1';

// Activity Object ID constants
final reactionObjectId = 'story-welcome-new-members-object-1';

final now = DateTime.now();

final reactionActivity1 = ActivityMock(
  mockEventId: reactionEventId,
  mockType: PushStyles.reaction.name,
  mockSenderId: 'quinn',
  mockRoomId: 'community-hub',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: reactionObjectId,
    mockType: 'story',
    mockTitle: 'Welcome New Members',
  ),
);

final reactionActivity2 = ActivityMock(
  mockEventId: reactionEventId,
  mockType: PushStyles.reaction.name,
  mockSenderId: 'annaz',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: reactionObjectId,
    mockType: 'news',
    mockTitle: 'Welcome team Members',
  ),
);

final reactionActivity3 = ActivityMock(
  mockEventId: reactionEventId,
  mockType: PushStyles.reaction.name,
  mockSenderId: 'quinn',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: reactionObjectId,   
    mockType: 'news',
    mockTitle: 'Welcome New Members',
  ),
);
