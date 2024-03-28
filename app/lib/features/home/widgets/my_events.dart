import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/calendar_widget.dart';
import 'package:acter/features/events/widgets/events_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MyEventsSection extends ConsumerWidget {
  final int? limit;

  const MyEventsSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(allUpcomingEventsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          L10n.of(context).events,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: CalendarWidget(),
        ),
        const SizedBox(height: 15),
        Text(
          L10n.of(context).upcoming,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        EventsList(
          limit: limit,
          events: upcoming,
        ),
      ],
    );
  }
}
