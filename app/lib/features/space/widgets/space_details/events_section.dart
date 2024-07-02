import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EventsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const EventsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eventsLabel(context),
        eventsList(context, ref),
      ],
    );
  }

  Widget eventsLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            L10n.of(context).events,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () {},
            child: Text(L10n.of(context).seeAll),
          ),
        ],
      ),
    );
  }

  Widget eventsList(BuildContext context, WidgetRef ref) {
    final eventsList = ref.watch(spaceEventsProvider(spaceId));

    return eventsList.when(
      data: (events) {
        int eventsLimit = (events.length > limit) ? limit : events.length;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: eventsLimit,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return EventItem(event: events[index]);
          },
        );
      },
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }
}
