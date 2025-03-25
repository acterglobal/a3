import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter/features/spaces/pages/create_space/permission_selection_bottom_sheet.dart';

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
          if (isFeatureActivated) _buildPermissionsList(feature, featureState),
        ],
      ),
    );
  }

  Widget _buildPermissionsList(
    SpaceFeature feature,
    FeatureState featureState,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions:',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...featureState.permissions.map(
            (permission) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 4),
                Text('${permission.displayText}:', style: textTheme.bodySmall),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder:
                          (context) => PermissionSelectionBottomSheet(
                            currentPermission: permission.defaultLevel,
                            onPermissionSelected: (level) {
                              ref
                                  .read(featureActivationProvider.notifier)
                                  .update((state) {
                                    final newState =
                                        Map<SpaceFeature, FeatureState>.from(
                                          state,
                                        );
                                    final updatedPermissions =
                                        featureState.permissions.map((p) {
                                          if (p.key == permission.key) {
                                            return p.copyWith(
                                              defaultLevel: level,
                                            );
                                          }
                                          return p;
                                        }).toList();
                                    newState[feature] = featureState.copyWith(
                                      permissions: updatedPermissions,
                                    );
                                    return newState;
                                  });
                            },
                          ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      permission.defaultLevel.name.toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
