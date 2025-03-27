import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/actions/select_permission.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SpaceFeaturesWidget extends ConsumerStatefulWidget {
  const SpaceFeaturesWidget({super.key});

  @override
  ConsumerState<SpaceFeaturesWidget> createState() =>
      _SpaceFeaturesWidgetState();
}

class _SpaceFeaturesWidgetState extends ConsumerState<SpaceFeaturesWidget> {
  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.spaceFeatures, style: textTheme.bodyMedium),
        Text(lang.spaceFeaturesDes, style: textTheme.labelSmall),
        const SizedBox(height: 8),
        _buildFeatureItems(
          SpaceFeature.boosts,
          PhosphorIcons.rocketLaunch(),
          lang.boosts,
          lang.boostsDes,
        ),
        _buildFeatureItems(
          SpaceFeature.stories,
          PhosphorIcons.slideshow(),
          lang.stories,
          lang.storeisDes,
        ),
        _buildFeatureItems(
          SpaceFeature.pins,
          Atlas.pin,
          lang.pins,
          lang.pinsDes,
        ),
        _buildFeatureItems(
          SpaceFeature.events,
          Atlas.calendar,
          lang.events,
          lang.eventsDes,
        ),
        _buildFeatureItems(
          SpaceFeature.tasks,
          Atlas.list,
          lang.tasks,
          lang.tasksDes,
        ),
      ],
    );
  }

  Widget _buildFeatureItems(
    SpaceFeature feature,
    IconData featureIcon,
    String featureName,
    String featureDescription,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final featureStates = ref.watch(featureActivationStateProvider);
    final featureState = featureStates[feature] ?? FeatureActivationState();
    final isFeatureActivated = featureState.isActivated;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(featureIcon),
            title: Text(featureName, style: textTheme.bodyMedium),
            subtitle: Text(featureDescription, style: textTheme.labelMedium),
            trailing: Switch(
              value: isFeatureActivated,
              onChanged: (value) {
                ref.read(featureActivationStateProvider.notifier).update((
                  state,
                ) {
                  final newState =
                      Map<SpaceFeature, FeatureActivationState>.from(state);
                  newState[feature] = featureState.copyWith(isActivated: value);
                  return newState;
                });
              },
            ),
          ),
          if (isFeatureActivated) _buildPermissionsList(feature, featureState),
        ],
      ),
    );
  }

  Widget _buildPermissionsList(
    SpaceFeature spaceFeature,
    FeatureActivationState featureState,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.permissionsSubtitle,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...featureState.permissions.map(
            (permissionItem) => _buildPermissionItem(
              permissionItem,
              spaceFeature,
              featureState,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    PermissionConfig permissionItem,
    SpaceFeature spaceFeature,
    FeatureActivationState featureState,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final lang = L10n.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 16),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(switch (permissionItem.key) {
            PermissionType.boostPost => lang.boostPermissionsDesc,
            PermissionType.storyPost => lang.storyPermissionsDesc,
            PermissionType.pinPost => lang.pinPermissionsDesc,
            PermissionType.eventPost => lang.eventPermissionsDesc,
            PermissionType.taskListPost => lang.taskListPermissionsDesc,
            PermissionType.taskItemPost => lang.taskItemPermissionsDesc,
            PermissionType.eventRsvp => lang.eventRsvpPermissionsDesc,
            PermissionType.commentPost => lang.commentPermissionsDesc,
            PermissionType.attachmentPost => lang.attachmentPermissionsDesc,
          }, style: textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap:
              () => _onTapChangePermission(
                spaceFeature,
                featureState,
                permissionItem,
              ),
          child: Text(
            permissionItem.permissionLevel.name.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  void _onTapChangePermission(
    SpaceFeature spaceFeature,
    FeatureActivationState featureState,
    PermissionConfig permissionItem,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SelectPermission(
            currentPermission: permissionItem.permissionLevel,
            onPermissionSelected: (level) {
              ref.read(featureActivationStateProvider.notifier).update((state) {
                final newState = Map<SpaceFeature, FeatureActivationState>.from(
                  state,
                );
                final updatedPermissions =
                    featureState.permissions.map((p) {
                      if (p.key == permissionItem.key) {
                        return p.copyWith(permissionLevel: level);
                      }
                      return p;
                    }).toList();
                newState[spaceFeature] = featureState.copyWith(
                  permissions: updatedPermissions,
                );
                return newState;
              });
            },
          ),
    );
  }
}
