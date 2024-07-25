import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/events_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class MyEventsSection extends ConsumerWidget {
  final int? limit;

  const MyEventsSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(myUpcomingEventsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Text(
              L10n.of(context).upcomingEvents,
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
          events: upcoming,
        ),
      ],
    );
  }
}
