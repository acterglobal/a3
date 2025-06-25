import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity_object.dart';
import 'package:acter_notifify/model/push_styles.dart';

final now = DateTime.now();

final eventCreationActivity1 = MockActivity(
  mockActivityId: 'event-creation-activity-indiv-1',
  mockType: PushStyles.creation.name,
  mockSubType: 'event_created',
  mockSenderId: 'frank',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'event-q1-campaign-launch-object-1',
    mockType: 'event',
    mockTitle: 'Q1 Campaign Launch',
  ),
);

final rsvpYesActivity1 = MockActivity(
  mockActivityId: 'rsvp-yes-activity-indiv-1',
  mockType: PushStyles.rsvpYes.name,
  mockSubType: 'event_rsvp',
  mockSenderId: 'grace',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'event-brand-strategy-workshop-object-1',
    mockType: 'event',
    mockTitle: 'Brand Strategy Workshop',
  ),
);

final rsvpMaybeActivity1 = MockActivity(
  mockActivityId: 'rsvp-maybe-activity-indiv-1',
  mockType: PushStyles.rsvpMaybe.name,
  mockSubType: 'event_rsvp',
  mockSenderId: 'henry',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'event-client-feedback-session-object-1',
    mockType: 'event',
    mockTitle: 'Client Feedback Session',
  ),
);

final taskCompleteActivity1 = MockActivity(
  mockActivityId: 'task-complete-activity-indiv-1',
  mockType: PushStyles.taskComplete.name,
  mockSubType: 'task_status',
  mockSenderId: 'jack',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'task-social-media-calendar-object-1',
    mockType: 'task',
    mockTitle: 'Social Media Calendar',
  ),
);

final taskReopenActivity1 = MockActivity(
  mockActivityId: 'task-reopen-activity-indiv-1',
  mockType: PushStyles.taskReOpen.name,
  mockSubType: 'task_status',
  mockSenderId: 'kelly',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'task-website-content-update-object-1',
    mockType: 'task',
    mockTitle: 'Website Content Update',
  ),
);
