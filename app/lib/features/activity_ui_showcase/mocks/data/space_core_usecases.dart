import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter_notifify/model/push_styles.dart';

final now = DateTime.now();

final roomNameActivity1 = MockActivity(
  mockActivityId: 'room-name-activity-space-core-1',
  mockType: PushStyles.roomName.name,
  mockSubType: 'room_settings',
  mockSenderId: '@oscar:acter.global',
  mockRoomId: 'design-team',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1, hours: 10)).millisecondsSinceEpoch,
);

final roomAvatarActivity1 = MockActivity(
  mockActivityId: 'room-avatar-activity-space-core-1',
  mockType: PushStyles.roomAvatar.name,
  mockSubType: 'room_settings',
  mockSenderId: '@paula:acter.global',
  mockRoomId: 'design-team',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1, hours: 11)).millisecondsSinceEpoch,
);
