import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:acter/features/spaces/model/space_permission_levels.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter/features/spaces/pages/create_space/permission_selection_bottom_sheet.dart';

final featureActivationProvider =
    StateProvider<Map<SpaceFeature, FeatureState>>(
      (ref) => {
        SpaceFeature.boost: FeatureState(),
        SpaceFeature.story: FeatureState(),
        SpaceFeature.pin: FeatureState(),
        SpaceFeature.calendar: FeatureState(),
        SpaceFeature.task: FeatureState(),
        SpaceFeature.comment: FeatureState(),
        SpaceFeature.attachment: FeatureState(),
      },
    );

class SpaceFeaturesActivation extends ConsumerStatefulWidget {
  const SpaceFeaturesActivation({super.key});

  @override
  ConsumerState<SpaceFeaturesActivation> createState() =>
      _SpaceFeaturesActivationState();
}

class _SpaceFeaturesActivationState
    extends ConsumerState<SpaceFeaturesActivation> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Space Features', style: textTheme.bodyMedium),
        Text(
          'Customize your experience by turning on the features that matter most to you.',
          style: textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        _buildFeatureActivation(
          SpaceFeature.boost,
          PhosphorIcons.rocketLaunch(),
          'Boost',
          'Boost updates important to your space members',
        ),
        _buildFeatureActivation(
          SpaceFeature.story,
          PhosphorIcons.slideshow(),
          'Story',
          'Socialize updates with your space members',
        ),
        _buildFeatureActivation(
          SpaceFeature.pin,
          Atlas.pin,
          'Pin',
          'Pin important links and data in your space',
        ),
        _buildFeatureActivation(
          SpaceFeature.calendar,
          Atlas.calendar,
          'Calendar',
          'Manage events in your space',
        ),
        _buildFeatureActivation(
          SpaceFeature.task,
          Atlas.list,
          'Task',
          'Manage tasks in your space',
        ),
        _buildFeatureActivation(
          SpaceFeature.comment,
          Atlas.comment,
          'Comment',
          'Allow members to comment on space objects',
        ),
        _buildFeatureActivation(
          SpaceFeature.attachment,
          Atlas.paperclip,
          'Attachment',
          'Allow members to attach files to space objects',
        ),
      ],
    );
  }

  Widget _buildFeatureActivation(
    SpaceFeature feature,
    IconData featureIcon,
    String featureName,
    String featureDescription,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final featureStates = ref.watch(featureActivationProvider);
    final featureState = featureStates[feature] ?? FeatureState();
    final isFeatureActivated = featureState.isActivated;
    final permissionLevel = featureState.permissionLevel;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(featureIcon),
            title: Text(featureName, style: textTheme.bodyMedium),
            subtitle: Text(featureDescription, style: textTheme.labelSmall),
            trailing: Switch(
              value: isFeatureActivated,
              onChanged: (value) {
                ref.read(featureActivationProvider.notifier).update((state) {
                  final newState = Map<SpaceFeature, FeatureState>.from(state);
                  newState[feature] = featureState.copyWith(isActivated: value);
                  return newState;
                });
              },
            ),
          ),
          if (isFeatureActivated)
            _buildPermissionLevel(feature, featureState, permissionLevel),
        ],
      ),
    );
  }

  Widget _buildPermissionLevel(
    SpaceFeature feature,
    FeatureState featureState,
    PermissionLevel permissionLevel,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 16),
          const SizedBox(width: 4),
          Text('Permission level :', style: textTheme.bodySmall),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder:
                    (context) => PermissionSelectionBottomSheet(
                      currentPermission: permissionLevel,
                      onPermissionSelected: (level) {
                        ref.read(featureActivationProvider.notifier).update((
                          state,
                        ) {
                          final newState = Map<SpaceFeature, FeatureState>.from(
                            state,
                          );
                          newState[feature] = featureState.copyWith(
                            permissionLevel: level,
                          );
                          return newState;
                        });
                      },
                    ),
              );
            },
            child: Text(
              permissionLevel.name.toUpperCase(),
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
