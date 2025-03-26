import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureActivationProvider = StateProvider<
  Map<SpaceFeature, FeatureActivationState>
>(
  (ref) => {
    SpaceFeature.boosts: FeatureActivationState(permissions: boostPermissions),
    SpaceFeature.stories: FeatureActivationState(permissions: storyPermissions),
    SpaceFeature.pins: FeatureActivationState(permissions: pinPermissions),
    SpaceFeature.events: FeatureActivationState(
      permissions: calendarPermissions,
    ),
    SpaceFeature.tasks: FeatureActivationState(permissions: taskPermissions),
  },
);
