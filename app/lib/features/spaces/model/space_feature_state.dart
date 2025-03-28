import 'package:acter/features/spaces/model/permission_config.dart';

class FeatureActivationState {
  final bool isActivated;
  final List<PermissionConfig> permissions;

  FeatureActivationState({
    this.isActivated = false,
    List<PermissionConfig>? permissions,
  }) : permissions = permissions ?? [];

  FeatureActivationState copyWith({
    bool? isActivated,
    List<PermissionConfig>? permissions,
  }) {
    return FeatureActivationState(
      isActivated: isActivated ?? this.isActivated,
      permissions: permissions ?? this.permissions,
    );
  }
}
