import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::pin::select_drawer');

const Key selectPinDrawerKey = Key('select-pin-drawer');

Future<String?> selectPinDrawer({
  required BuildContext context,
  required String spaceId,
  Key? key = selectPinDrawerKey,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final calPinLoader = ref.watch(pinsProvider(spaceId));
        return calPinLoader.when(
          data: (pinsList) => Column(
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
                      child: title ?? const Text('Select pin'),
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
                child: pinsList.isEmpty
                    ? Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: const Text('No events found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: pinsList.length,
                        itemBuilder: (context, index) => PinListItemWidget(
                          pinId: pinsList[index].eventIdStr(),
                          onTaPinItem: (pinId) {
                            Navigator.pop(context, pinId);
                          },
                        ),
                      ),
              ),
            ],
          ),
          error: (e, s) {
            _log.severe('Failed to load pin list', e, s);
            return Center(
              child: Text(L10n.of(context).loadingFailed(e)),
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
