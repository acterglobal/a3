import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureActivationProvider =
    StateProvider<Map<SpaceFeature, FeatureState>>(
      (ref) => {
        SpaceFeature.boost: FeatureState(permissions: boostPermissions),
        SpaceFeature.story: FeatureState(permissions: storyPermissions),
        SpaceFeature.pin: FeatureState(permissions: pinPermissions),
        SpaceFeature.calendar: FeatureState(permissions: calendarPermissions),
        SpaceFeature.task: FeatureState(permissions: taskPermissions),
        SpaceFeature.comment: FeatureState(permissions: commentPermissions),
        SpaceFeature.attachment: FeatureState(
          permissions: attachmentPermissions,
        ),
      },
    );
