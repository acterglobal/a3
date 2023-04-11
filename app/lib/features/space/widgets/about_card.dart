import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutCard extends ConsumerWidget {
  final String spaceId;
  const AboutCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceId));
    final members = ref.watch(spaceMembersProvider(spaceId));

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
            ...members.when(
              data: (members) {
                final membersCount = members.length;
                if (membersCount > 10) {
                  // too many to display, means we limit to 10
                  members = members.sublist(0, 10);
                }
                return [
                  Text(
                    'Members ($membersCount)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    direction: Axis.horizontal,
                    spacing: -6,
                    children: [
                      ...members.map(
                        (a) => MemberAvatar(member: a),
                      )
                    ],
                  ),
                ];
              },
              error: (error, stack) => [Text('Loading members failed: $error')],
              loading: () => [const Text('Loading')],
            )
          ],
        ),
      ),
    );
  }
}
