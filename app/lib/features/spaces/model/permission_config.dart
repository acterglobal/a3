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
