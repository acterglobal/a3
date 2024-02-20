import 'dart:math';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/events_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventsCard extends ConsumerWidget {
  final String spaceId;

  const EventsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(spaceEventsProvider(spaceId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        events.when(
          error: (error, stackTrace) => Text(
            'Loading events failed: $error',
          ),
          data: (events) {
            int eventsLimit = min(events.length, 3);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                events.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: eventsLimit,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, idx) =>
                            EventItem(event: events[idx]),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'There are no events scheduled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                eventsLimit != events.length
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton(
                          onPressed: () => context.pushNamed(
                            Routes.spaceEvents.name,
                            pathParameters: {'spaceId': spaceId},
                          ),
                          child: Text('See all my ${events.length} events'),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
        ),
      ],
    );
  }
}
