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

class FeatureState {
  final bool isActivated;
  final List<PermissionConfig> permissions;

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

  FeatureState({this.isActivated = false, List<PermissionConfig>? permissions})
    : permissions = permissions ?? defaultPermissions;

  FeatureState copyWith({
    bool? isActivated,
    List<PermissionConfig>? permissions,
  }) {
    return FeatureState(
      isActivated: isActivated ?? this.isActivated,
      permissions: permissions ?? this.permissions,
    );
  }
}
