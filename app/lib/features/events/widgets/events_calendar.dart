import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

// ignore: must_be_immutable
class EventsCalendar extends ConsumerWidget {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final AsyncValue<List<CalendarEvent>> events;

  EventsCalendar({super.key, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        Text(
          'Events',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        events.when(
          error: (error, stackTrace) => Text(
            'Loading calendars failed: $error',
          ),
          data: (events) {
            return Column(
              children: [
                ...events.map(
                  (e) => ListTile(
                    onTap: () => context.pushNamed(
                      Routes.calendarEvent.name,
                      pathParameters: {'calendarId': e.eventId().toString()},
                    ),
                    title: Text(
                      e.title(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      formatDt(e),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TableCalendar<CalendarEvent>(
                  firstDay: kFirstDay,
                  lastDay: kLastDay,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  calendarFormat: _calendarFormat,
                  rangeSelectionMode: _rangeSelectionMode,
                  eventLoader: (targetDate) => eventsForDay(events, targetDate),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    // Use `CalendarStyle` to customize the UI
                    outsideDaysVisible: false,
                    rangeHighlightColor: Theme.of(context).colorScheme.tertiary,
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  // onDaySelected: _onDaySelected,
                  // onRangeSelected: _onRangeSelected,
                  // onFormatChanged: (format) {
                  //   if (_calendarFormat != format) {
                  //     setState(() {
                  //       _calendarFormat = format;
                  //     });
                  //   }
                  // },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ],
            );
          },
          loading: () => TableCalendar(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
          ),
        ),
        // space.when(
        //   data: (space) {
        //     final topic = space.topic();
        //     return Text(topic ?? 'no topic found');
        //   },
        //   error: (error, stack) => Text('Loading failed: $error'),
        //   loading: () => const Text('Loading'),
        // ),
      ],
    );
  }
}
