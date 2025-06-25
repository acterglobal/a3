import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter_notifify/model/push_styles.dart';

// Activity ID constants
final roomNameEventId = 'room-name-activity-space-core-1';
final roomAvatarEventId = 'room-avatar-activity-space-core-1';

final now = DateTime.now();

final roomNameActivity1 = ActivityMock(
  mockEventId: roomNameEventId,
  mockType: PushStyles.roomName.name,
  mockSubType: 'room_settings',
  mockSenderId: '@oscar:acter.global',
  mockRoomId: 'design-team',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1, hours: 10)).millisecondsSinceEpoch,
);

final roomAvatarActivity1 = ActivityMock(
  mockEventId: roomAvatarEventId,
  mockType: PushStyles.roomAvatar.name,
  mockSubType: 'room_settings',
  mockSenderId: '@paula:acter.global',
  mockRoomId: 'design-team',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1, hours: 11)).millisecondsSinceEpoch,
);
