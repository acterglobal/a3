import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity_object.dart';
import 'package:acter_notifify/model/push_styles.dart';

// Activity ID constants (following chat mock pattern)
final eventCreationEventId = 'event-creation-activity-indiv-1';
final rsvpYesEventId = 'rsvp-yes-activity-indiv-1';
final rsvpMaybeEventId = 'rsvp-maybe-activity-indiv-1';
final taskCompleteEventId = 'task-complete-activity-indiv-1';
final taskReopenEventId = 'task-reopen-activity-indiv-1';

// Activity Object ID constants (for the activity objects themselves)
final eventCreationObjectId = 'event-q1-campaign-launch-object-1';
final rsvpYesObjectId = 'event-brand-strategy-workshop-object-1';
final rsvpMaybeObjectId = 'event-client-feedback-session-object-1';
final taskCompleteObjectId = 'task-social-media-calendar-object-1';
final taskReopenObjectId = 'task-website-content-update-object-1';

final now = DateTime.now();

final eventCreationActivity1 = ActivityMock(
  mockEventId: eventCreationEventId,
  mockType: PushStyles.creation.name,
  mockSubType: 'event_created',
  mockSenderId: 'frank',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: eventCreationObjectId,
    mockType: 'event',
    mockTitle: 'Q1 Campaign Launch',
  ),
);

final rsvpYesActivity1 = ActivityMock(
  mockEventId: rsvpYesEventId,
  mockType: PushStyles.rsvpYes.name,
  mockSubType: 'event_rsvp',
  mockSenderId: 'grace',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: rsvpYesObjectId,
    mockType: 'event',
    mockTitle: 'Brand Strategy Workshop',
  ),
);

final rsvpMaybeActivity1 = ActivityMock(
  mockEventId: rsvpMaybeEventId,
  mockType: PushStyles.rsvpMaybe.name,
  mockSubType: 'event_rsvp',
  mockSenderId: 'henry',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: rsvpMaybeObjectId,
    mockType: 'event',
    mockTitle: 'Client Feedback Session',
  ),
);

final taskCompleteActivity1 = ActivityMock(
  mockEventId: taskCompleteEventId,
  mockType: PushStyles.taskComplete.name,
  mockSubType: 'task_status',
  mockSenderId: 'jack',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: taskCompleteObjectId,
    mockType: 'task',
    mockTitle: 'Social Media Calendar',
  ),
);

final taskReopenActivity1 = ActivityMock(
  mockEventId: taskReopenEventId,
  mockType: PushStyles.taskReOpen.name,
  mockSubType: 'task_status',
  mockSenderId: 'kelly',
  mockRoomId: 'marketing-team',
  mockOriginServerTs:
      now.subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
  mockObject: ActivityMockObject(
    mockObjectId: taskReopenObjectId,
    mockType: 'task',
    mockTitle: 'Website Content Update',
  ),
);
