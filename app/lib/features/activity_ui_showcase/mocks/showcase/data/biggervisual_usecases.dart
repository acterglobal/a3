import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity_object.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_description_content.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_ref_details.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_room_topic_content.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_title_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:acter_notifify/model/push_styles.dart';

final now = DateTime.now();

final pinCommentActivity1 = MockActivity(
  mockActivityId: 'pin-comment-activity-bigvis-1',
  mockType: PushStyles.comment.name,
  mockSubType: 'pin',
  mockSenderId: 'alice',
  mockRoomId: 'development-team',
  mockOriginServerTs:
      now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'pin-project-proposal-object-1',
    mockType: 'pin',
    mockTitle: 'Project Proposal Document',
  ),
  mockMsgContent: MockMsgContent(
    mockBody:
        'Great insights on the technical approach! Looking forward to implementation.',
  ),
);

final documentAttachmentActivity1 = MockActivity(
  mockActivityId: 'document-attachment-activity-bigvis-1',
  mockType: PushStyles.attachment.name,
  mockSubType: 'document',
  mockSenderId: 'charlie',
  mockRoomId: 'development-team',
  mockOriginServerTs:
      now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'pin-sprint-planning-object-1',
    mockType: 'pin',
    mockTitle: 'Sprint Planning Notes',
  ),
  mockMsgContent: MockMsgContent(mockBody: 'Meeting notes and action items'),
);

final eventReferenceActivity1 = MockActivity(
  mockActivityId: 'event-reference-activity-bigvis-1',
  mockType: PushStyles.references.name,
  mockSubType: 'event_reference',
  mockSenderId: 'david',
  mockRoomId: 'development-team',
  mockOriginServerTs:
      now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'event-sprint-planning-object-1',
    mockType: 'event',
    mockTitle: 'Event',
  ),
  mockMsgContent: MockMsgContent(mockBody: 'Event Description'),
  mockRefDetails: MockRefDetails(
    mockTitle: 'Sprint Planning Meeting',
    mockType: 'calendar-event',
    mockTargetId: 'sprint-planning-event-id',
  ),
);

final taskAddActivity1 = MockActivity(
  mockActivityId: 'task-add-activity-bigvis-1',
  mockType: PushStyles.taskAdd.name,
  mockSubType: 'task_list',
  mockSenderId: 'elena',
  mockRoomId: 'development-team',
  mockOriginServerTs:
      now.subtract(const Duration(minutes: 45)).millisecondsSinceEpoch,
  mockName: 'Code Review Guidelines',
  mockObject: MockActivityObject(
    mockObjectId: 'task-list-code-review-object-1',
    mockType: 'task-list',
    mockTitle: 'Code Review Process',
  ),
);

final taskTitleChangeActivity1 = MockActivity(
  mockActivityId: 'task-title-change-activity-bigvis-1',
  mockType: PushStyles.titleChange.name,
  mockSubType: 'task_title_change',
  mockSenderId: 'elena',
  mockRoomId: 'development-team',
  mockOriginServerTs:
      now.subtract(const Duration(minutes: 50)).millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'task-list-code-review-object-2',
    mockType: 'task-list',
    mockTitle: 'Code Review Process',
  ),
  mockTitleContent: MockTitleContent(
    mockChange: 'Changed',
    mockNewVal: 'Code Review Process',
  ),
);

final roomTopicChangeActivity1 = MockActivity(
  mockActivityId: 'room-topic-change-activity-bigvis-1',
  mockType: PushStyles.roomTopic.name,
  mockSubType: 'space_description',
  mockSenderId: 'diana',
  mockRoomId: 'development-team',
  mockOriginServerTs:
      now.subtract(const Duration(minutes: 35)).millisecondsSinceEpoch,
  mockName:
      'Updated space description to reflect new project scope and objectives',
  mockRoomTopicContent: MockRoomTopicContent(
    mockChange: 'Changed',
    mockNewVal:
        'A collaborative space for the development team to plan, discuss, and execute technical projects. We focus on code quality, innovative solutions, and continuous improvement.',
    mockOldVal: 'Development team workspace',
  ),
);

final descriptionChangeActivity1 = MockActivity(
  mockActivityId: 'description-change-activity-bigvis-1',
  mockType: PushStyles.descriptionChange.name,
  mockSubType: 'pin_description_change',
  mockSenderId: 'quinn',
  mockRoomId: 'community-hub',
  mockOriginServerTs:
      now
          .subtract(const Duration(hours: 12, minutes: 15))
          .millisecondsSinceEpoch,
  mockObject: MockActivityObject(
    mockObjectId: 'pin-community-guidelines-object-1',
    mockType: 'pin',
    mockTitle: 'Community Guidelines',
  ),
  mockDescriptionContent: MockDescriptionContent(
    mockChange: 'Changed',
    mockNewVal:
        'Updated community guidelines to reflect our growing membership and new collaboration tools. Please review the latest changes and ensure all team members are aware.',
  ),
);
