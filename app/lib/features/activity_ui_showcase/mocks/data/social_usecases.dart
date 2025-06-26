import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity_object.dart';
import 'package:acter_notifify/model/push_styles.dart';

final now = DateTime.now();

final reactionActivity1 = MockActivity(
  mockActivityId: 'reaction-activity-social-1',
  mockType: PushStyles.reaction.name,
  mockSenderId: 'quinn',
  mockRoomId: 'community-hub',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'story-welcome-new-members-object-1',
    mockType: 'story',
    mockTitle: 'Welcome New Members',
  ),
);

final reactionActivity2 = MockActivity(
  mockActivityId: 'reaction-activity-social-2',
  mockType: PushStyles.reaction.name,
  mockSenderId: 'annaz',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'news-welcome-new-members-object-1',
    mockType: 'news',
    mockTitle: 'Welcome team Members',
  ),
);

final reactionActivity3 = MockActivity(
  mockActivityId: 'reaction-activity-social-3',
  mockType: PushStyles.reaction.name,
  mockSenderId: 'quinn',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'news-welcome-new-members-object-2',   
    mockType: 'news',
    mockTitle: 'Welcome New Members',
  ),
);
