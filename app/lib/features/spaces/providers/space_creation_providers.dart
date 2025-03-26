import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureActivationProvider =
    StateProvider<Map<SpaceFeature, FeatureState>>(
      (ref) => {
        SpaceFeature.boosts: FeatureState(permissions: boostPermissions),
        SpaceFeature.stories: FeatureState(permissions: storyPermissions),
        SpaceFeature.pins: FeatureState(permissions: pinPermissions),
        SpaceFeature.events: FeatureState(permissions: calendarPermissions),
        SpaceFeature.tasks: FeatureState(permissions: taskPermissions),
      },
    );
