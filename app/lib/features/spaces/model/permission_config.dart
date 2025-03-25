enum PermissionLevel { admin, moderator, member }

class PermissionConfig {
  final String key;
  final String displayText;
  final PermissionLevel defaultLevel;

  const PermissionConfig({
    required this.key,
    required this.displayText,
    this.defaultLevel = PermissionLevel.admin,
  });

  PermissionConfig copyWith({
    String? key,
    String? displayText,
    PermissionLevel? defaultLevel,
  }) {
    return PermissionConfig(
      key: key ?? this.key,
      displayText: displayText ?? this.displayText,
      defaultLevel: defaultLevel ?? this.defaultLevel,
    );
  }
}

const boostPermissions = [
  PermissionConfig(
    key: 'boost-post',
    displayText: 'Who can post Boosts',
    defaultLevel: PermissionLevel.admin,
  ),
];

const storyPermissions = [
  PermissionConfig(
    key: 'story-post',
    displayText: 'Who can post Stories',
    defaultLevel: PermissionLevel.admin,
  ),
];
const pinPermissions = [
  PermissionConfig(
    key: 'pin-post',
    displayText: 'Who can create Pins',
    defaultLevel: PermissionLevel.admin,
  ),
];

const calendarPermissions = [
  PermissionConfig(
    key: 'event-post',
    displayText: 'Who can create Events',
    defaultLevel: PermissionLevel.admin,
  ),
  PermissionConfig(
    key: 'rsvp',
    displayText: 'Who can RSVP to Events',
    defaultLevel: PermissionLevel.admin,
  ),
];

const taskPermissions = [
  PermissionConfig(
    key: 'task-list-post',
    displayText: 'Who can create Task Lists',
    defaultLevel: PermissionLevel.admin,
  ),
  PermissionConfig(
    key: 'task-item-post',
    displayText: 'Who can add Task Items',
    defaultLevel: PermissionLevel.admin,
  ),
];

const commentPermissions = [
  PermissionConfig(
    key: 'comment-post',
    displayText: 'Who can post Comments',
    defaultLevel: PermissionLevel.member,
  ),
];

final attachmentPermissions = [
  PermissionConfig(
    key: 'attachment-post',
    displayText: 'Who can attach files',
    defaultLevel: PermissionLevel.member,
  ),
];
