import 'package:acter/features/spaces/model/space_permission_levels.dart';

enum SpaceFeature { boost, story, pin, calendar, task, comment, attachment }

class PermissionConfig {
  final String key;
  final String displayText;
  final PermissionLevel defaultLevel;

  const PermissionConfig({
    required this.key,
    required this.displayText,
    this.defaultLevel = PermissionLevel.admin,
  });
}

class FeatureState {
  final bool isActivated;
  final Map<String, PermissionConfig> permissions;

  static const defaultPermissions = [
    PermissionConfig(
      key: 'create',
      displayText: 'Create',
      defaultLevel: PermissionLevel.admin,
    ),
    PermissionConfig(
      key: 'read',
      displayText: 'View',
      defaultLevel: PermissionLevel.member,
    ),
    PermissionConfig(
      key: 'update',
      displayText: 'Edit',
      defaultLevel: PermissionLevel.admin,
    ),
    PermissionConfig(
      key: 'delete',
      displayText: 'Delete',
      defaultLevel: PermissionLevel.admin,
    ),
  ];

  FeatureState({
    this.isActivated = false,
    Map<String, PermissionConfig>? permissions,
  }) : permissions =
           permissions ??
           {for (var config in defaultPermissions) config.key: config};

  FeatureState copyWith({
    bool? isActivated,
    Map<String, PermissionConfig>? permissions,
  }) {
    return FeatureState(
      isActivated: isActivated ?? this.isActivated,
      permissions: permissions ?? this.permissions,
    );
  }
}
