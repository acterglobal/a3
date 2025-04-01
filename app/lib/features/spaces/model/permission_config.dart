import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

enum PermissionLevel {
  admin(100),
  moderator(50),
  everyone(0);

  final int value;
  const PermissionLevel(this.value);
}

String getPermissionNameFromLevel(
  BuildContext context,
  PermissionLevel permissionLevel,
) {
  final lang = L10n.of(context);
  return switch (permissionLevel) {
    PermissionLevel.admin => lang.admin,
    PermissionLevel.moderator => lang.moderator,
    PermissionLevel.everyone => lang.everyone,
  };
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
    permissionLevel: PermissionLevel.admin,
  ),
];

const storyPermissions = [
  PermissionConfig(
    key: PermissionType.storyPost,
    permissionLevel: PermissionLevel.everyone,
  ),
];
const pinPermissions = [
  PermissionConfig(
    key: PermissionType.pinPost,
    permissionLevel: PermissionLevel.moderator,
  ),
];

const calendarPermissions = [
  PermissionConfig(
    key: PermissionType.eventPost,
    permissionLevel: PermissionLevel.moderator,
  ),
  PermissionConfig(
    key: PermissionType.eventRsvp,
    permissionLevel: PermissionLevel.everyone,
  ),
];

const taskPermissions = [
  PermissionConfig(
    key: PermissionType.taskListPost,
    permissionLevel: PermissionLevel.admin,
  ),
  PermissionConfig(
    key: PermissionType.taskItemPost,
    permissionLevel: PermissionLevel.moderator,
  ),
];

const commentPermissions = [
  PermissionConfig(
    key: PermissionType.commentPost,
    permissionLevel: PermissionLevel.everyone,
  ),
];

final attachmentPermissions = [
  PermissionConfig(
    key: PermissionType.attachmentPost,
    permissionLevel: PermissionLevel.everyone,
  ),
];
