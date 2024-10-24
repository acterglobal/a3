import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::cal_event::select_drawer');

const Key selectEventDrawerKey = Key('event-widgets-select-event-drawer');

Future<String?> selectEventDrawer({
  required BuildContext context,
  required String spaceId,
  Key? key = selectEventDrawerKey,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final calEventsLoader = ref.watch(allEventListProvider(spaceId));
        return calEventsLoader.when(
          data: (calEvents) => Column(
            key: key,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: title ?? const Text('Select event'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Atlas.minus_circle_thin),
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: calEvents.isEmpty
                    ? Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: const Text('No events found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: calEvents.length,
                        itemBuilder: (context, index) => EventItem(
                          event: calEvents[index],
                          isShowRsvp: false,
                          eventType:
                              ref.read(eventTypeProvider(calEvents[index])),
                          onTapEventItem: (event) {
                            Navigator.pop(context, event);
                          },
                        ),
                      ),
              ),
            ],
          ),
          error: (e, s) {
            _log.severe('Failed to load all cal events', e, s);
            return Center(
              child: Text(L10n.of(context).failedToLoadEventsDueTo(e)),
            );
          },
          loading: () => const SizedBox(
            height: 500,
            child: EventListSkeleton(),
          ),
        );
      },
    ),
  );
  if (selected == '') {
    // in case of being cleared, we return null
    return null;
  }
  return selected;
}
