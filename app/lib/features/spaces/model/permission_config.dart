enum PermissionLevel {
  admin(100),
  moderator(50),
  member(0);

  final int value;
  const PermissionLevel(this.value);
}

class PermissionConfig {
  final String key;
  final String displayText;
  final PermissionLevel permissionLevel;

  const PermissionConfig({
    required this.key,
    required this.displayText,
    this.permissionLevel = PermissionLevel.admin,
  });

  PermissionConfig copyWith({
    String? key,
    String? displayText,
    PermissionLevel? permissionLevel,
  }) {
    return PermissionConfig(
      key: key ?? this.key,
      displayText: displayText ?? this.displayText,
      permissionLevel: permissionLevel ?? this.permissionLevel,
    );
  }
}

const boostPermissions = [
  PermissionConfig(
    key: 'boost-post',
    displayText: 'Who can post Boosts',
    permissionLevel: PermissionLevel.admin,
  ),
];

const storyPermissions = [
  PermissionConfig(
    key: 'story-post',
    displayText: 'Who can post Stories',
    permissionLevel: PermissionLevel.admin,
  ),
];
const pinPermissions = [
  PermissionConfig(
    key: 'pin-post',
    displayText: 'Who can create Pins',
    permissionLevel: PermissionLevel.admin,
  ),
];

const calendarPermissions = [
  PermissionConfig(
    key: 'event-post',
    displayText: 'Who can create Events',
    permissionLevel: PermissionLevel.admin,
  ),
  PermissionConfig(
    key: 'event-rsvp',
    displayText: 'Who can RSVP to Events',
    permissionLevel: PermissionLevel.admin,
  ),
];

const taskPermissions = [
  PermissionConfig(
    key: 'task-list-post',
    displayText: 'Who can create Task Lists',
    permissionLevel: PermissionLevel.admin,
  ),
  PermissionConfig(
    key: 'task-item-post',
    displayText: 'Who can add Task Items',
    permissionLevel: PermissionLevel.admin,
  ),
];

const commentPermissions = [
  PermissionConfig(
    key: 'comment-post',
    displayText: 'Who can post Comments',
    permissionLevel: PermissionLevel.member,
  ),
];

final attachmentPermissions = [
  PermissionConfig(
    key: 'attachment-post',
    displayText: 'Who can attach files',
    permissionLevel: PermissionLevel.member,
  ),
];
