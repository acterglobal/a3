import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
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
      child: Column(
        children: [
          const ListTile(title: Text('About')),
          space.when(
            data: (space) {
              final topic = space.topic();
              return Text(topic ?? 'no topic found');
            },
            error: (error, stack) => Text('Loading failed: $error'),
            loading: () => const Text('Loading'),
          ),
          ...members.when(
            data: (members) {
              final membersCount = members.length;
              if (membersCount > 10) {
                // too many to display, means we limit to 10
                members = members.sublist(0, 10);
              }
              return [
                ListTile(title: Text('Members ($membersCount)')),
                ...members.map((a) => MemberAvatar(member: a))
              ];
            },
            error: (error, stack) => [Text('Loading members failed: $error')],
            loading: () => [const Text('Loading')],
          )
        ],
      ),
    );
  }
}
