import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/widgets/events_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: must_be_immutable
class EventsCard extends ConsumerWidget {
  final String spaceId;
  const EventsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(spaceEventsProvider(spaceId));

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: EventsCalendar(
          events: events,
        ),
      ),
    );
  }
}
