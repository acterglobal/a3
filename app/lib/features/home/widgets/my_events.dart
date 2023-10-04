import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/events/presentation/widgets/events_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyEventsSection extends ConsumerWidget {
  final int? limit;
  const MyEventsSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingEventsProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          EventsCalendar(limit: limit, events: upcoming),
        ],
      ),
    );
  }
}
