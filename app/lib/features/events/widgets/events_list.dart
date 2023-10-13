import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/features/events/widgets/events_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventsList extends ConsumerWidget {
  final int? limit;
  final AsyncValue<List<CalendarEvent>> events;

  const EventsList({super.key, this.limit, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return events.when(
      error: (error, stackTrace) => Text(
        'Loading events failed: $error',
      ),
      data: (events) {
        int eventsLimit =
            (limit != null && events.length > limit!) ? limit! : events.length;
        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              events.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: eventsLimit,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, idx) =>
                              EventItem(event: events[idx]),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'At this moment, you are not joining any upcoming events. To find out what events are scheduled, check your spaces.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
              eventsLimit != events.length
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: DefaultButton(
                        onPressed: () =>
                            context.pushNamed(Routes.calendarEvents.name),
                        title: 'See all my ${events.length} events',
                        isOutlined: true,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}
