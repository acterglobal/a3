import 'package:acter/features/spaces/model/permission_config.dart';

class FeatureState {
  final bool isActivated;
  final List<PermissionConfig> permissions;

  FeatureState({this.isActivated = false, List<PermissionConfig>? permissions})
    : permissions = permissions ?? [];

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
