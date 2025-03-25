import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final featureActivationProvider = StateProvider<bool>((ref) => false);

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
          PhosphorIcons.rocketLaunch(),
          'Boost',
          'Boost updates important to your space members',
        ),
        _buildFeatureActivation(
          PhosphorIcons.slideshow(),
          'Story',
          'Socialize updates with your space members',
        ),
        _buildFeatureActivation(
          Atlas.pin,
          'Pin',
          'Pin important links and data in your space',
        ),
        _buildFeatureActivation(
          Atlas.calendar,
          'Calendar',
          'Manage events in your space',
        ),
        _buildFeatureActivation(
          Atlas.list,
          'Task',
          'Manage tasks in your space',
        ),
      ],
    );
  }

  Widget _buildFeatureActivation(
    IconData featureIcon,
    String featureName,
    String featureDescription,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final isFeatureActivated = ref.watch(featureActivationProvider);
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
              value: ref.watch(featureActivationProvider),
              onChanged: (value) {
                ref
                    .read(featureActivationProvider.notifier)
                    .update((state) => value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
