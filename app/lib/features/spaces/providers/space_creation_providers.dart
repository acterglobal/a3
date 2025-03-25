import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:acter/features/spaces/model/space_permission_levels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureActivationProvider =
    StateProvider<Map<SpaceFeature, FeatureState>>(
      (ref) => {
        SpaceFeature.boost: FeatureState(
          permissions: {
            'post': PermissionConfig(
              key: 'post',
              displayText: 'Who can post Boosts',
              defaultLevel: PermissionLevel.admin,
            ),
          },
        ),
        SpaceFeature.story: FeatureState(
          permissions: {
            'post': PermissionConfig(
              key: 'post',
              displayText: 'Who can post Stories',
              defaultLevel: PermissionLevel.admin,
            ),
          },
        ),
        SpaceFeature.pin: FeatureState(
          permissions: {
            'post': PermissionConfig(
              key: 'post',
              displayText: 'Who can create Pins',
              defaultLevel: PermissionLevel.admin,
            ),
          },
        ),
        SpaceFeature.calendar: FeatureState(
          permissions: {
            'post': PermissionConfig(
              key: 'post',
              displayText: 'Who can create Events',
              defaultLevel: PermissionLevel.admin,
            ),
            'rsvp': PermissionConfig(
              key: 'rsvp',
              displayText: 'Who can RSVP to Events',
              defaultLevel: PermissionLevel.admin,
            ),
          },
        ),
        SpaceFeature.task: FeatureState(
          permissions: {
            'task-list-post': PermissionConfig(
              key: 'task-list-post',
              displayText: 'Who can create Task Lists',
              defaultLevel: PermissionLevel.admin,
            ),
            'task-item-post': PermissionConfig(
              key: 'task-item-post',
              displayText: 'Who can add Task Items',
              defaultLevel: PermissionLevel.admin,
            ),
          },
        ),
        SpaceFeature.comment: FeatureState(
          permissions: {
            'post': PermissionConfig(
              key: 'post',
              displayText: 'Who can post Comments',
              defaultLevel: PermissionLevel.member,
            ),
          },
        ),
        SpaceFeature.attachment: FeatureState(
          permissions: {
            'post': PermissionConfig(
              key: 'post',
              displayText: 'Who can attach files',
              defaultLevel: PermissionLevel.member,
            ),
          },
        ),
      },
    );
