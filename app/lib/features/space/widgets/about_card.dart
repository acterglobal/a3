import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutCard extends ConsumerWidget {
  final String spaceId;
  const AboutCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceId));
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            space.when(
              data: (space) {
                final topic = space.topic();
                return Text(
                  topic ?? 'no topic found',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              error: (error, stack) => Text('Loading failed: $error'),
              loading: () => const Text('Loading'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
