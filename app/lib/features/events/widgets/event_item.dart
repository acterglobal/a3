import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/widgets/blinking_text.dart';
import 'package:acter/features/events/actions/get_event_type.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/features/events/widgets/event_date_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent, RsvpStatusTag;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cal_event::event_item');

class EventItem extends StatelessWidget {
  final CalendarEvent event;
  final EdgeInsetsGeometry? margin;
  final Function(String)? onTapEventItem;
  final bool isShowRsvp;
  final bool isShowSpaceName;

  const EventItem({
    super.key,
    required this.event,
    this.margin,
    this.onTapEventItem,
    this.isShowRsvp = true,
    this.isShowSpaceName = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final eventId = event.eventId().toString();
        onTapEventItem.map((cb) => cb(eventId)) ??
            context.pushNamed(
              Routes.calendarEvent.name,
              pathParameters: {'calendarId': eventId},
            );
      },
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Card(
            margin: margin,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                EventDateWidget(calendarEvent: event),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventTitle(context),
                      Consumer(builder: _buildEventSubtitle),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (getEventType(event) == EventFilters.ongoing)
                  _buildHappeningIndication(context),
                const SizedBox(width: 10),
                if (isShowRsvp) _buildRsvpStatus(context),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTitle(BuildContext context) {
    return Text(
      event.title(),
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventSubtitle(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    String eventSpaceName =
        ref.watch(roomDisplayNameProvider(event.roomIdStr())).valueOrNull ??
            L10n.of(context).unknown;
    String eventDateTime = '${formatDate(event)} (${formatTime(event)})';
    return Text(
      isShowSpaceName ? eventSpaceName : eventDateTime,
      style: Theme.of(context).textTheme.labelLarge,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRsvpStatus(BuildContext context) {
    final lang = L10n.of(context);
    return Consumer(
      builder: (context, ref, child) {
        final eventId = event.eventId().toString();
        final rsvpLoader = ref.watch(myRsvpStatusProvider(eventId));
        return rsvpLoader.when(
          data: (status) {
            final widget = _getRsvpStatus(context, status); // kebab-case
            return widget ?? const SizedBox.shrink();
          },
          error: (e, s) {
            _log.severe('Failed to load RSVP status', e, s);
            return Chip(
              label: Text(
                lang.errorLoadingRsvpStatus(e),
                softWrap: true,
              ),
            );
          },
          loading: () => Chip(
            label: Text(lang.loadingRsvpStatus),
          ),
        );
      },
    );
  }

  Widget? _getRsvpStatus(BuildContext context, RsvpStatusTag? status) {
    return switch (status) {
      RsvpStatusTag.Yes => Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.secondary,
        ),
      RsvpStatusTag.No => Icon(
          Icons.cancel,
          color: Theme.of(context).colorScheme.error,
        ),
      RsvpStatusTag.Maybe => const Icon(Icons.question_mark_rounded),
      _ => null,
    };
  }

  Widget _buildHappeningIndication(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: BlinkText(
        L10n.of(context).live,
        style: Theme.of(context).textTheme.labelLarge,
        beginColor: Colors.white,
        endColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
