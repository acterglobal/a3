import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventItem extends ConsumerWidget {
  final CalendarEvent event;
  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = event.eventId().toString();
    final myRsvpStatus = ref.watch(myRsvpStatusProvider(eventId));
    return Card(
      child: ListTile(
        title:
            Text(event.title(), style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(
          '${formatDt(event)} (${formatTime(event)})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: myRsvpStatus.when(
          data: (status) {
            return Chip(
              label: Text(status),
            );
          },
          error: (e, st) => Chip(
            label: Text('Error loading rsvp status: $e', softWrap: true),
          ),
          loading: () => const Chip(label: Text('Loading rsvp status')),
        ),
        onTap: () => context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': event.eventId().toString()},
        ),
      ),
    );
  }
}
