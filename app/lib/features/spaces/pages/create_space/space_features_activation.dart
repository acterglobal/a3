import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum SpaceFeature { boost, story, pin, calendar, task }

final featureActivationProvider = StateProvider<Map<SpaceFeature, bool>>(
  (ref) => {
    SpaceFeature.boost: false,
    SpaceFeature.story: false,
    SpaceFeature.pin: false,
    SpaceFeature.calendar: false,
    SpaceFeature.task: false,
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
    final isFeatureActivated = featureStates[feature] ?? false;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(featureIcon),
            title: Text(featureName, style: textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(featureDescription, style: textTheme.labelSmall),
                if (isFeatureActivated) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Permission level :', style: textTheme.bodySmall),
                      const SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Switch(
              value: isFeatureActivated,
              onChanged: (value) {
                ref.read(featureActivationProvider.notifier).update((state) {
                  final newState = Map<SpaceFeature, bool>.from(state);
                  newState[feature] = value;
                  return newState;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
