import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventItem extends StatelessWidget {
  final CalendarEvent event;
  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(event.title()),
      subtitle: Text(
        formatDt(event),
      ),
      onTap: () => context.pushNamed(
        Routes.calendarEvent.name,
        pathParameters: {'calendarId': event.eventId().toString()},
      ),
    );
  }
}
