import 'package:acter/features/events/widgets/events_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsCalendar extends ConsumerWidget {
  final AsyncValue<List<CalendarEvent>> events;

  const EventsCalendar({super.key, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return events.when(
      error: (error, stackTrace) => Text(
        'Loading events failed: $error',
      ),
      data: (events) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            events.isNotEmpty
                ? ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      events.length,
                      (idx) => EventItem(event: events[idx]),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'At this moment, you are not joining any upcoming events. To find out what events are scheduled, check your spaces.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}
