import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_date_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
        if (onTapEventItem != null) {
          onTapEventItem!(event.eventId().toString());
          return;
        }
        context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': event.eventId().toString()},
        );
      },
      child: Card(
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isShowRsvp) _buildRsvpStatus(context),
            const SizedBox(width: 10),
          ],
        ),
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
    return Consumer(
      builder: (context, ref, child) {
        final eventId = event.eventId().toString();
        final myRsvpStatus = ref.watch(myRsvpStatusProvider(eventId));
        return myRsvpStatus.when(
          data: (data) {
            final status = data.statusStr(); // kebab-case
            return Chip(label: Text(_getStatusLabel(context, status)));
          },
          error: (e, st) => Chip(
            label: Text(
              L10n.of(context).errorLoadingRsvpStatus(e),
              softWrap: true,
            ),
          ),
          loading: () => Chip(
            label: Text(L10n.of(context).loadingRsvpStatus),
          ),
        );
      },
    );
  }

  String _getStatusLabel(BuildContext context, String? status) {
    if (status != null) {
      switch (status) {
        case 'yes':
          return L10n.of(context).going;
        case 'no':
          return L10n.of(context).notGoing;
        case 'maybe':
          return L10n.of(context).maybe;
      }
    }
    return L10n.of(context).pending;
  }
}
