import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class EventDateWidget extends StatelessWidget {
  final CalendarEvent calendarEvent;
  final EventFilters eventType;

  const EventDateWidget({
    super.key,
    required this.calendarEvent,
    required this.eventType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final day = getDayFromDate(calendarEvent.utcStart());
    final month = getMonthFromDate(calendarEvent.utcStart());
    final startTime = getTimeFromDate(context, calendarEvent.utcStart());

    return Card(
      color: getColorBasedOnEventType(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(month, style: textTheme.titleSmall),
                const SizedBox(width: 4),
                Text(day, style: textTheme.titleSmall),
              ],
            ),
            Text(startTime, style: textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Color getColorBasedOnEventType(BuildContext context) => switch (eventType) {
        EventFilters.past => Colors.grey.shade800,
        _ => Theme.of(context).primaryColor
      };
}
