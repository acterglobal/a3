import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/event_utils/event_utils.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class EventDateWidget extends StatelessWidget {
  final CalendarEvent calendarEvent;
  final double size;

  const EventDateWidget({
    super.key,
    required this.calendarEvent,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return _buildEventDate(context);
  }

  Widget _buildEventDate(BuildContext context) {
    final day = getDayFromDate(calendarEvent.utcStart());
    final month = getMonthFromDate(calendarEvent.utcStart());

    return Card(
      color: getColorBasedOnEventType(context),
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(month),
            Text(day, style: Theme.of(context).textTheme.titleLarge),
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
