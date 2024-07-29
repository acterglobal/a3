import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/events_list.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class MyEventsSection extends ConsumerWidget {
  final int? limit;
  final EventFilters eventFilters;

  const MyEventsSection({
    super.key,
    this.limit,
    this.eventFilters = EventFilters.upcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<CalendarEvent>> myEvents;
    String sectionTitle = '';
    if (eventFilters == EventFilters.ongoing) {
      myEvents = ref.watch(myOngoingEventListProvider(null));
      sectionTitle = L10n.of(context).myOngoingEvents;
    } else {
      myEvents = ref.watch(myUpcomingEventListProvider(null));
      sectionTitle = L10n.of(context).myUpcomingEvents;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            ActerInlineTextButton(
              onPressed: () => context.pushNamed(Routes.calendarEvents.name),
              child: Text(L10n.of(context).seeAll),
            ),
          ],
        ),
        EventsList(
          limit: limit,
          events: myEvents,
        ),
      ],
    );
  }
}
