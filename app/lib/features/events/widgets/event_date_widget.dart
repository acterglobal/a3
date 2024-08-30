import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/actions/get_event_type.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class EventDateWidget extends StatelessWidget {
  final CalendarEvent calendarEvent;

  const EventDateWidget({super.key, required this.calendarEvent});

  @override
  Widget build(BuildContext context) {
    return _buildEventDate(context);
  }

  Widget _buildEventDate(BuildContext context) {
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
                Text(month, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 4),
                Text(day, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            Text(startTime, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Color getColorBasedOnEventType(BuildContext context) {
    if (getEventType(calendarEvent) == EventFilters.past) {
      return Colors.grey.shade800;
    } else {
      return Theme.of(context).primaryColor;
    }
  }
}
