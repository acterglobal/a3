const _supportedGeneralStateEventTypes = [
  'MembershipChange',
  'ProfileChange',
  'm.room.redaction',
  'm.room.encrypted',
];

const supportedRoomUpdateStateEvents = {
  'm.policy.rule.room',
  'm.policy.rule.server',
  'm.policy.rule.user',
  'm.room.aliases',
  'm.room.avatar',
  'm.room.canonical_alias',
  'm.room.create',
  'm.room.encryption',
  'm.room.guest_access',
  'm.room.history_visibility',
  'm.room.join_rules',
  'm.room.name',
  'm.room.pinned_events',
  'm.room.power_levels',
  'm.room.server_acl',
  'm.room.third_party_invite',
  'm.room.tombstone',
  'm.room.topic',
  'm.space.child',
  'm.space.parent',
};
const supportedStateEventTypes = [
  ..._supportedGeneralStateEventTypes,
  ...supportedRoomUpdateStateEvents,
];

const supportedMessageEventTypes = ['m.room.message'];

const supportedEventTypes = [
  ...supportedMessageEventTypes,
  ...supportedStateEventTypes,
];
