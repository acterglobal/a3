import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EventsList extends ConsumerWidget {
  final int? limit;
  final AsyncValue<List<CalendarEvent>> events;

  const EventsList({super.key, this.limit, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return events.when(
      error: (error, stackTrace) => Text(
        L10n.of(context).loadingEventsFailed(error),
      ),
      data: (events) {
        int eventsLimit =
            (limit != null && events.length > limit!) ? limit! : events.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            events.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: eventsLimit,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, idx) =>
                        EventItem(event: events[idx]),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      L10n.of(context).atThisMomentYouAreNotJoiningEvents,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
            eventsLimit != events.length
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton(
                      onPressed: () =>
                          context.pushNamed(Routes.calendarEvents.name),
                      child: Text(
                        L10n.of(context).seeAllMyEvents(events.length),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      },
      loading: () => const EventListSkeleton(),
    );
  }
}
