enum PermissionLevel {
  admin(100),
  moderator(50),
  everyone(0);

  final int value;
  const PermissionLevel(this.value);
}

enum PermissionType {
  boostPost,
  storyPost,
  pinPost,
  eventPost,
  taskListPost,
  taskItemPost,
  eventRsvp,
  commentPost,
  attachmentPost,
}

class PermissionConfig {
  final PermissionType key;
  final PermissionLevel permissionLevel;

  const PermissionConfig({
    required this.key,
    this.permissionLevel = PermissionLevel.admin,
  });

  PermissionConfig copyWith({
    PermissionType? key,
    PermissionLevel? permissionLevel,
  }) {
    return PermissionConfig(
      key: key ?? this.key,
      permissionLevel: permissionLevel ?? this.permissionLevel,
    );
  }
}

const boostPermissions = [
  PermissionConfig(
    key: PermissionType.boostPost,
    // displayText: 'Who can post Boosts',
    permissionLevel: PermissionLevel.admin,
  ),
];

const storyPermissions = [
  PermissionConfig(
    key: PermissionType.storyPost,
    // displayText: 'Who can post Stories',
    permissionLevel: PermissionLevel.everyone,
  ),
];
const pinPermissions = [
  PermissionConfig(
    key: PermissionType.pinPost,
    // displayText: 'Who can create Pins',
    permissionLevel: PermissionLevel.moderator,
  ),
];

const calendarPermissions = [
  PermissionConfig(
    key: PermissionType.eventPost,
    // displayText: 'Who can create Events',
    permissionLevel: PermissionLevel.moderator,
  ),
  PermissionConfig(
    key: PermissionType.eventRsvp,
    // displayText: 'Who can RSVP to Events',
    permissionLevel: PermissionLevel.everyone,
  ),
];

const taskPermissions = [
  PermissionConfig(
    key: PermissionType.taskListPost,
    // displayText: 'Who can create Task Lists',
    permissionLevel: PermissionLevel.admin,
  ),
  PermissionConfig(
    key: PermissionType.taskItemPost,
    // displayText: 'Who can add Task Items',
    permissionLevel: PermissionLevel.moderator,
  ),
];

const commentPermissions = [
  PermissionConfig(
    key: PermissionType.commentPost,
    // displayText: 'Who can post Comments',
    permissionLevel: PermissionLevel.everyone,
  ),
];

final attachmentPermissions = [
  PermissionConfig(
    key: PermissionType.attachmentPost,
    // displayText: 'Who can attach files',
    permissionLevel: PermissionLevel.everyone,
  ),
];
