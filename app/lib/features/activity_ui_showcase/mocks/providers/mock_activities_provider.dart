import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_membership_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Mock room topic content to show actual description changes
class MockRoomTopicContent extends Mock implements RoomTopicContent {
  final String? mockChange;
  final String mockNewVal;
  final String? mockOldVal;

  MockRoomTopicContent({
    this.mockChange,
    required this.mockNewVal,
    this.mockOldVal,
  });

  @override
  String? change() => mockChange ?? 'Changed';

  @override
  String newVal() => mockNewVal;

  @override
  String? oldVal() => mockOldVal;
}

// Mock ref details to show referenced objects in references activity
class MockRefDetails extends Mock implements RefDetails {
  final String mockTitle;
  final String mockType;
  final String? mockTargetId;

  MockRefDetails({
    required this.mockTitle,
    required this.mockType,
    this.mockTargetId,
  });

  @override
  String title() => mockTitle;

  @override
  String typeStr() => mockType;

  @override
  String? targetIdStr() => mockTargetId;
}

// Mock title content to show title changes
class MockTitleContent extends Mock implements TitleContent {
  final String mockChange;
  final String mockNewVal;

  MockTitleContent({required this.mockChange, required this.mockNewVal});

  @override
  String change() => mockChange;

  @override
  String newVal() => mockNewVal;
}

// Mock description content to show description changes
class MockDescriptionContent extends Mock implements DescriptionContent {
  final String mockChange;
  final String? mockNewVal;

  MockDescriptionContent({required this.mockChange, this.mockNewVal});

  @override
  String change() => mockChange;

  @override
  String? newVal() => mockNewVal;
}

class ActivityMockObject extends Mock implements ActivityObject {
  final String mockType;
  final String? mockObjectId;
  final String? mockTitle;
  final String? mockEmoji;

  ActivityMockObject({
    required this.mockType,
    this.mockObjectId,
    this.mockTitle,
    this.mockEmoji,
  });

  @override
  String typeStr() => mockType;

  @override
  String objectIdStr() => mockObjectId ?? 'object-id';

  @override
  String? title() => mockTitle ?? '';

  @override
  String emoji() => mockEmoji ?? '🚀';
}

class ActivityMock extends Mock implements Activity {
  final String mockType;
  final String? mockName;
  final String? mockSubType;
  final String? mockSenderId;
  final String? mockRoomId;
  final ActivityObject? mockObject;
  final MsgContent? mockMsgContent;
  final MembershipContent? mockMembershipContent;
  final RoomTopicContent? mockRoomTopicContent;
  final RefDetails? mockRefDetails;
  final TitleContent? mockTitleContent;
  final DescriptionContent? mockDescriptionContent;
  final int? mockOriginServerTs;

  ActivityMock({
    required this.mockType,
    this.mockName,
    this.mockSubType,
    this.mockSenderId,
    this.mockRoomId,
    this.mockObject,
    this.mockMsgContent,
    this.mockMembershipContent,
    this.mockRoomTopicContent,
    this.mockRefDetails,
    this.mockTitleContent,
    this.mockDescriptionContent,
    this.mockOriginServerTs,
  });

  @override
  String typeStr() => mockType;

  @override
  String? name() => mockName;

  @override
  String? subTypeStr() => mockSubType;

  @override
  String senderIdStr() => mockSenderId ?? 'sender-id';

  @override
  String roomIdStr() => mockRoomId ?? 'room-id';

  @override
  ActivityObject? object() => mockObject;

  @override
  MsgContent? msgContent() => mockMsgContent;

  @override
  MembershipContent? membershipContent() => mockMembershipContent;

  @override
  RoomTopicContent? roomTopicContent() => mockRoomTopicContent;

  @override
  RefDetails? refDetails() => mockRefDetails;

  @override
  TitleContent? titleContent() => mockTitleContent;

  @override
  DescriptionContent? descriptionContent() => mockDescriptionContent;

  @override
  int originServerTs() => mockOriginServerTs ?? DateTime.now().millisecondsSinceEpoch;

  // Default implementations for optional methods
  @override
  DateContent? dateContent() => null;

  @override
  DateTimeRangeContent? dateTimeRangeContent() => null;

  @override
  RoomAvatarContent? roomAvatarContent() => null;

  @override
  RoomNameContent? roomNameContent() => null;

  @override
  String? roomName() => null;

  @override
  String? roomAvatar() => null;
}

// Provider that creates a flat list of mock activities for allActivitiesProvider
final mockAllActivitiesProvider = Provider<List<Activity>>((ref) {
  final now = DateTime.now();
  
  return [
    // Today's activities - Development Team space
    ActivityMock(
      mockType: PushStyles.comment.name,
      mockSubType: 'pin',
      mockSenderId: '@alice:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'pin',
        mockTitle: 'Project Proposal Document',
      ),
      mockMsgContent: MockMsgContent(
        mockBody: 'Great insights on the technical approach! Looking forward to implementation.',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.attachment.name,
      mockSubType: 'document',
      mockSenderId: '@charlie:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'pin',
        mockTitle: 'Sprint Planning Notes',
      ),
      mockMsgContent: MockMsgContent(
        mockBody: 'Meeting notes and action items',
      ),
    ),
     ActivityMock(
      mockType: PushStyles.references.name,
      mockSubType: 'event_reference',
      mockSenderId: '@david:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'event',
        mockTitle: 'Event',
      ),
      mockMsgContent: MockMsgContent(
        mockBody: 'Event Description',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Sprint Planning Meeting',
        mockType: 'calendar-event',
        mockTargetId: 'sprint-planning-event-id',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.taskAdd.name,
      mockSubType: 'task_list',
      mockSenderId: '@elena:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 45)).millisecondsSinceEpoch,
      mockName: 'Code Review Guidelines',
      mockObject: ActivityMockObject(
        mockType: 'task-list',
        mockTitle: 'Code Review Process',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.titleChange.name,
      mockSubType: 'task_title_change',
      mockSenderId: '@elena:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 50)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'task-list',
        mockTitle: 'Code Review Process',
      ),
      mockTitleContent: MockTitleContent(
        mockChange: 'Changed',
        mockNewVal: 'Comprehensive Code Review Guidelines',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.roomTopic.name,
      mockSubType: 'space_description',
      mockSenderId: '@diana:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 35)).millisecondsSinceEpoch,
      mockName: 'Updated space description to reflect new project scope and objectives',
      mockRoomTopicContent: MockRoomTopicContent(
        mockChange: 'Changed',
        mockNewVal: 'A collaborative space for the development team to plan, discuss, and execute technical projects. We focus on code quality, innovative solutions, and continuous improvement.',
        mockOldVal: 'Development team workspace',
      ),
    ),

    // Today's activities - Marketing Team space
    ActivityMock(
      mockType: PushStyles.creation.name,
      mockSubType: 'event_created',
      mockSenderId: '@frank:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'event',
        mockTitle: 'Q1 Campaign Launch',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.titleChange.name,
      mockSubType: 'event_title_change',
      mockSenderId: '@frank:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 1, minutes: 15)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'event',
        mockTitle: 'Q1 Campaign Launch',
      ),
      mockTitleContent: MockTitleContent(
        mockChange: 'Changed',
        mockNewVal: 'Q1 Marketing Campaign Launch Event',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.descriptionChange.name,
      mockSubType: 'event_description_change',
      mockSenderId: '@grace:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 1, minutes: 30)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'event',
        mockTitle: 'Q1 Campaign Launch',
      ),
      mockDescriptionContent: MockDescriptionContent(
        mockChange: 'Set',
        mockNewVal: 'Join us for the official launch of our Q1 marketing campaign. We\'ll be presenting the new creative direction, campaign goals, and timeline for execution.',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.rsvpYes.name,
      mockSubType: 'event_rsvp',
      mockSenderId: '@grace:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'event',
        mockTitle: 'Brand Strategy Workshop',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.rsvpMaybe.name,
      mockSubType: 'event_rsvp',
      mockSenderId: '@henry:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'event',
        mockTitle: 'Client Feedback Session',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.taskComplete.name,
      mockSubType: 'task_status',
      mockSenderId: '@jack:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'task',
        mockTitle: 'Social Media Calendar',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.taskReOpen.name,
      mockSubType: 'task_status',
      mockSenderId: '@kelly:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'task',
        mockTitle: 'Website Content Update',
      ),
    ),

    // Today's activities - Community Hub space
    ActivityMock(
      mockType: PushStyles.reaction.name,
      mockSubType: 'story_reaction',
      mockSenderId: '@quinn:acter.global',
      mockRoomId: 'community-hub',
      mockOriginServerTs: now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'story',
        mockTitle: 'Welcome New Members',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.descriptionChange.name,
      mockSubType: 'pin_description_change',
      mockSenderId: '@quinn:acter.global',
      mockRoomId: 'community-hub',
      mockOriginServerTs: now.subtract(const Duration(hours: 12, minutes: 15)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'pin',
        mockTitle: 'Community Guidelines',
      ),
      mockDescriptionContent: MockDescriptionContent(
        mockChange: 'Changed',
        mockNewVal: 'Updated community guidelines to reflect our growing membership and new collaboration tools. Please review the latest changes and ensure all team members are aware.',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.reaction.name,
      mockSubType: 'news_reaction',
      mockSenderId: '@rachel:acter.global',
      mockRoomId: 'community-hub',
      mockOriginServerTs: now.subtract(const Duration(hours: 13)).millisecondsSinceEpoch,
      mockObject: ActivityMockObject(
        mockType: 'news',
        mockTitle: 'Monthly Newsletter',
      ),
    ),

    // Yesterday's activities - Project Alpha space (with proper membership content)
    ActivityMock(
      mockType: PushStyles.joined.name,
      mockSubType: 'membership_change',
      mockSenderId: '@sam:acter.global',
      mockRoomId: 'project-alpha',
      mockOriginServerTs: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      mockMembershipContent: MockMembershipContent(
        mockMembershipType: 'joined',
        mockUserId: '@sam:acter.global',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.invitationAccepted.name,
      mockSubType: 'invitation_response',
      mockSenderId: '@tina:acter.global',
      mockRoomId: 'project-alpha',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 2)).millisecondsSinceEpoch,
      mockMembershipContent: MockMembershipContent(
        mockMembershipType: 'invitationAccepted',
        mockUserId: '@tina:acter.global',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.invited.name,
      mockSubType: 'invitation_sent',
      mockSenderId: '@uma:acter.global',
      mockRoomId: 'project-alpha',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 4)).millisecondsSinceEpoch,
      mockMembershipContent: MockMembershipContent(
        mockMembershipType: 'invited',
        mockUserId: '@victor:acter.global',
      ),
    ),

    // Yesterday's activities - Design Team space
    ActivityMock(
      mockType: PushStyles.roomName.name,
      mockSubType: 'room_settings',
      mockSenderId: '@oscar:acter.global',
      mockRoomId: 'design-team',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 10)).millisecondsSinceEpoch,
    ),
    ActivityMock(
      mockType: PushStyles.roomAvatar.name,
      mockSubType: 'room_settings',
      mockSenderId: '@paula:acter.global',
      mockRoomId: 'design-team',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 11)).millisecondsSinceEpoch,
    ),

    // Two days ago - more membership activities in Product Team space
    ActivityMock(
      mockType: PushStyles.left.name,
      mockSubType: 'membership_change',
      mockSenderId: '@wendy:acter.global',
      mockRoomId: 'product-team',
      mockOriginServerTs: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      mockMembershipContent: MockMembershipContent(
        mockMembershipType: 'left',
        mockUserId: '@wendy:acter.global',
      ),
    ),
    ActivityMock(
      mockType: PushStyles.invitationRejected.name,
      mockSubType: 'invitation_response',
      mockSenderId: '@xavier:acter.global',
      mockRoomId: 'product-team',
      mockOriginServerTs: now.subtract(const Duration(days: 2, hours: 2)).millisecondsSinceEpoch,
      mockMembershipContent: MockMembershipContent(
        mockMembershipType: 'invitationRejected',
        mockUserId: '@xavier:acter.global',
      ),
    ),
  ];
});

// Legacy providers for backward compatibility
final mockActivityIdsProvider = Provider<List<String>>((ref) {
  final activities = ref.watch(mockAllActivitiesProvider);
  return activities.map((activity) => '${activity.roomIdStr()}-${activity.originServerTs()}').toList();
});

final mockActivityNamesProvider = Provider<Map<String, String>>((ref) {
  final activities = ref.watch(mockAllActivitiesProvider);
  final Map<String, String> names = {};
  for (final activity in activities) {
    final id = '${activity.roomIdStr()}-${activity.originServerTs()}';
    names[id] = activity.object()?.title() ?? activity.name() ?? '';
  }
  return names;
});

final mockActivityNameProvider = Provider.family<String?, String>((ref, activityId) {
  final names = ref.watch(mockActivityNamesProvider);
  return names[activityId];
}); 