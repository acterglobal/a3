import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/events/widgets/events_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: must_be_immutable
class EventsCard extends ConsumerWidget {
  final String spaceId;
  const EventsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(spaceEventsProvider(spaceId));
    return EventsCalendar(
      events: events,
    );
  }
}
