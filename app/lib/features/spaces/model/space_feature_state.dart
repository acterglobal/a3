import 'package:acter/features/spaces/model/space_permission_levels.dart';

enum SpaceFeature { boost, story, pin, calendar, task, comment, attachment }

class FeatureState {
  final bool isActivated;
  final PermissionLevel permissionLevel;

  FeatureState({
    this.isActivated = false,
    this.permissionLevel = PermissionLevel.admin,
  });

  FeatureState copyWith({bool? isActivated, PermissionLevel? permissionLevel}) {
    return FeatureState(
      isActivated: isActivated ?? this.isActivated,
      permissionLevel: permissionLevel ?? this.permissionLevel,
    );
  }
}
