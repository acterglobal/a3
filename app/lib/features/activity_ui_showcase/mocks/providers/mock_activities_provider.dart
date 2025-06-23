import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Mock implementations of the real Activity interfaces
class MockActivityObject extends Mock implements ActivityObject {
  final String mockType;
  final String? mockObjectId;
  final String? mockTitle;
  final String? mockEmoji;

  MockActivityObject({
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

class MockMsgContent extends Mock implements MsgContent {
  final String? mockBody;
  final String? mockFormattedBody;

  MockMsgContent({this.mockBody, this.mockFormattedBody});

  @override
  String body() => mockBody ?? 'message body';

  @override
  String? formattedBody() => mockFormattedBody;
}

class MockActivity extends Mock implements Activity {
  final String mockType;
  final String? mockName;
  final String? mockSubType;
  final String? mockSenderId;
  final String? mockRoomId;
  final ActivityObject? mockObject;
  final MsgContent? mockMsgContent;
  final int? mockOriginServerTs;

  MockActivity({
    required this.mockType,
    this.mockName,
    this.mockSubType,
    this.mockSenderId,
    this.mockRoomId,
    this.mockObject,
    this.mockMsgContent,
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
  int originServerTs() => mockOriginServerTs ?? DateTime.now().millisecondsSinceEpoch;

  // Default implementations for optional methods
  @override
  TitleContent? titleContent() => null;

  @override
  DescriptionContent? descriptionContent() => null;

  @override
  DateContent? dateContent() => null;

  @override
  DateTimeRangeContent? dateTimeRangeContent() => null;

  @override
  MembershipContent? membershipContent() => null;

  @override
  RoomAvatarContent? roomAvatarContent() => null;

  @override
  RoomNameContent? roomNameContent() => null;

  @override
  RoomTopicContent? roomTopicContent() => null;

  @override
  String? roomName() => null;

  @override
  String? roomAvatar() => null;

  @override
  RefDetails? refDetails() => null;
}

// Provider that creates a flat list of mock activities for allActivitiesProvider
final mockAllActivitiesProvider = Provider<List<Activity>>((ref) {
  final now = DateTime.now();
  
  return [
    // Today's activities - Development Team space
    MockActivity(
      mockType: PushStyles.comment.name,
      mockSenderId: '@alice:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'pin',
        mockTitle: 'Project Proposal Document',
      ),
      mockMsgContent: MockMsgContent(
        mockBody: 'Great insights on the technical approach! Looking forward to implementation.',
      ),
    ),
    MockActivity(
      mockType: PushStyles.attachment.name,
      mockSenderId: '@charlie:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'pin',
        mockTitle: 'Sprint Planning Notes',
      ),
      mockMsgContent: MockMsgContent(
        mockBody: 'Meeting notes and action items',
      ),
    ),
    MockActivity(
      mockType: PushStyles.taskAdd.name,
      mockSenderId: '@elena:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 45)).millisecondsSinceEpoch,
      mockName: 'Code Review Guidelines',
      mockObject: MockActivityObject(
        mockType: 'task-list',
        mockTitle: 'Code Review Process',
      ),
    ),
    MockActivity(
      mockType: PushStyles.roomTopic.name,
      mockSenderId: '@diana:acter.global',
      mockRoomId: 'development-team',
      mockOriginServerTs: now.subtract(const Duration(minutes: 35)).millisecondsSinceEpoch,
      mockName: 'Updated space description to reflect new project scope and objectives',
    ),

    // Today's activities - Marketing Team space
    MockActivity(
      mockType: PushStyles.creation.name,
      mockSenderId: '@frank:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockTitle: 'Q1 Campaign Launch',
      ),
    ),
    MockActivity(
      mockType: PushStyles.rsvpYes.name,
      mockSenderId: '@grace:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockTitle: 'Brand Strategy Workshop',
      ),
    ),
    MockActivity(
      mockType: PushStyles.rsvpMaybe.name,
      mockSenderId: '@henry:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockTitle: 'Client Feedback Session',
      ),
    ),
    MockActivity(
      mockType: PushStyles.taskComplete.name,
      mockSenderId: '@jack:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockTitle: 'Social Media Calendar',
      ),
    ),
    MockActivity(
      mockType: PushStyles.taskReOpen.name,
      mockSenderId: '@kelly:acter.global',
      mockRoomId: 'marketing-team',
      mockOriginServerTs: now.subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockTitle: 'Website Content Update',
      ),
    ),

    // Today's activities - Community Hub space
    MockActivity(
      mockType: PushStyles.reaction.name,
      mockSenderId: '@quinn:acter.global',
      mockRoomId: 'community-hub',
      mockOriginServerTs: now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'story',
        mockTitle: 'Welcome New Members',
      ),
    ),
    MockActivity(
      mockType: PushStyles.reaction.name,
      mockSenderId: '@rachel:acter.global',
      mockRoomId: 'community-hub',
      mockOriginServerTs: now.subtract(const Duration(hours: 13)).millisecondsSinceEpoch,
      mockObject: MockActivityObject(
        mockType: 'news',
        mockTitle: 'Monthly Newsletter',
      ),
    ),

    // Yesterday's activities - Project Alpha space
    MockActivity(
      mockType: PushStyles.joined.name,
      mockSenderId: '@sam:acter.global',
      mockRoomId: 'project-alpha',
      mockOriginServerTs: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
    ),
    MockActivity(
      mockType: PushStyles.invitationAccepted.name,
      mockSenderId: '@tina:acter.global',
      mockRoomId: 'project-alpha',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 2)).millisecondsSinceEpoch,
    ),
    MockActivity(
      mockType: PushStyles.invited.name,
      mockSenderId: '@uma:acter.global',
      mockRoomId: 'project-alpha',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 4)).millisecondsSinceEpoch,
      mockName: 'Victor Liu',
    ),

    // Yesterday's activities - Design Team space
    MockActivity(
      mockType: PushStyles.roomName.name,
      mockSenderId: '@oscar:acter.global',
      mockRoomId: 'design-team',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 10)).millisecondsSinceEpoch,
    ),
    MockActivity(
      mockType: PushStyles.roomAvatar.name,
      mockSenderId: '@paula:acter.global',
      mockRoomId: 'design-team',
      mockOriginServerTs: now.subtract(const Duration(days: 1, hours: 11)).millisecondsSinceEpoch,
    ),

    // Two days ago - more membership activities in Product Team space
    MockActivity(
      mockType: PushStyles.left.name,
      mockSenderId: '@wendy:acter.global',
      mockRoomId: 'product-team',
      mockOriginServerTs: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
    ),
    MockActivity(
      mockType: PushStyles.invitationRejected.name,
      mockSenderId: '@xavier:acter.global',
      mockRoomId: 'product-team',
      mockOriginServerTs: now.subtract(const Duration(days: 2, hours: 2)).millisecondsSinceEpoch,
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