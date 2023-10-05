import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:acter/features/events/presentation/widgets/events_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  final int? eventsLimit;
  const CalendarWidget({
    super.key,
    this.eventsLimit = 5,
  });

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetConsumerState();
}

class _CalendarWidgetConsumerState extends ConsumerState<CalendarWidget> {
  List<ffi.CalendarEvent> eventList = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  // ignore: prefer_final_fields
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  List<ffi.CalendarEvent> _getEventsForDay(
    DateTime day,
  ) {
    final calendarEvents = ref.watch(upcomingEventsProvider);
    final List<ffi.CalendarEvent> events =
        calendarEvents.hasValue ? calendarEvents.value! : [];

    return events.where((ev) {
      final evDay = toDartDatetime(ev.utcStart());
      return (evDay.eqvDay(day) && evDay.eqvMonth(day) && evDay.eqvYear(day));
    }).toList();
  }

  List<ffi.CalendarEvent> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      eventList = _getEventsForRange(start, end);
    } else if (start != null) {
      eventList = _getEventsForDay(start);
    } else if (end != null) {
      eventList = _getEventsForDay(end);
    }
  }

  void _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
  ) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
      eventList = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          focusedDay: _focusedDay,
          firstDay: kFirstDay,
          lastDay: kLastDay,
          currentDay: DateTime.now(),
          calendarFormat: _calendarFormat,
          rangeSelectionMode: _rangeSelectionMode,
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          rowHeight: 52.0,
          daysOfWeekHeight: 18.0,
          headerStyle: HeaderStyle(
            leftChevronIcon: Icon(
              Icons.chevron_left_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonPadding: const EdgeInsets.all(8),
            formatButtonTextStyle: Theme.of(context).textTheme.labelMedium!,
          ),
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.success,
              shape: BoxShape.circle,
            ),
            rangeHighlightColor:
                Theme.of(context).colorScheme.tertiaryContainer,
            rangeStartDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onTertiary,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onTertiary,
              shape: BoxShape.circle,
            ),
          ),
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onRangeSelected: _onRangeSelected,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          onDaySelected: _onDaySelected,
        ),
        Visibility(
          visible: eventList.isNotEmpty,
          replacement: const SizedBox.shrink(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: _rangeStart == null && _rangeEnd == null,
                replacement: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat.yMMMEd().format(_rangeStart ?? _focusedDay),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    _rangeEnd != null
                        ? Flexible(
                            child: Text(
                              ' - ${DateFormat.yMMMEd().format(_rangeEnd!)}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                child: Text(
                  (!_focusedDay.isToday())
                      ? DateFormat.yMMMEd().format(_focusedDay)
                      : 'Today Events',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eventList.length,
                itemBuilder: (ctx, index) {
                  return EventItem(event: eventList[index]);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
