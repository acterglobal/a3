import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsCard extends ConsumerWidget {
  final String spaceId;
  const EventsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceId));
    final members = ref.watch(spaceMembersProvider(spaceId));

    return Card(
      elevation: 0,
      child: Column(
        children: [
          const ListTile(title: Text('Events')),
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: DateTime.now(),
          ),
          // space.when(
          //   data: (space) {
          //     final topic = space.topic();
          //     return Text(topic ?? 'no topic found');
          //   },
          //   error: (error, stack) => Text('Loading failed: $error'),
          //   loading: () => const Text('Loading'),
          // ),
        ],
      ),
    );
  }
}
