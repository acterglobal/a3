import 'package:acter/features/events/providers.dart';
import 'package:acter/features/events/presentation/widgets/calendar_widget.dart';
import 'package:acter/features/events/presentation/widgets/events_list.dart';
import 'package:flutter/material.dart';
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
        children: <Widget>[
          Text(
            'Events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const CalendarWidget(),
          const SizedBox(height: 15),
          Text(
            'Upcoming',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          EventsList(
            limit: limit,
            events: upcoming,
          ),
        ],
      ),
    );
  }
}
