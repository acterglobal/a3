import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';

Map<SpaceFeature, FeatureActivationState> generateRecommendedSettings = {
  //BOOST Feature settings
  SpaceFeature.boosts: FeatureActivationState(
    isActivated: true,
    permissions: [
      PermissionConfig(
        key: PermissionType.boostPost,
        permissionLevel: PermissionLevel.moderator,
      ),
    ],
  ),

  //STORY Feature settings
  SpaceFeature.stories: FeatureActivationState(
    isActivated: true,
    permissions: [
      PermissionConfig(
        key: PermissionType.storyPost,
        permissionLevel: PermissionLevel.everyone,
      ),
    ],
  ),

  //PIN Feature settings
  SpaceFeature.pins: FeatureActivationState(
    isActivated: true,
    permissions: [
      PermissionConfig(
        key: PermissionType.pinPost,
        permissionLevel: PermissionLevel.everyone,
      ),
    ],
  ),

  //EVENT Feature settings
  SpaceFeature.events: FeatureActivationState(
    isActivated: true,
    permissions: [
      PermissionConfig(
        key: PermissionType.eventPost,
        permissionLevel: PermissionLevel.everyone,
      ),
      PermissionConfig(
        key: PermissionType.eventRsvp,
        permissionLevel: PermissionLevel.everyone,
      ),
    ],
  ),

  //TASK Feature settings
  SpaceFeature.tasks: FeatureActivationState(
    isActivated: true,
    permissions: [
      PermissionConfig(
        key: PermissionType.taskListPost,
        permissionLevel: PermissionLevel.everyone,
      ),
      PermissionConfig(
        key: PermissionType.taskItemPost,
        permissionLevel: PermissionLevel.everyone,
      ),
    ],
  ),
};
