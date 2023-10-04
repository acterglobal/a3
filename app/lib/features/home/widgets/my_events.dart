import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/events/widgets/events_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyEventsSection extends ConsumerWidget {
  final int? limit;
  const MyEventsSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(calendarEventsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: EventsCalendar(limit: limit, events: events),
    );
  }
}
