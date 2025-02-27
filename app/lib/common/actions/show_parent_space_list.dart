import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::actions::parent-space-list');

Future<void> showParentSpaceList(BuildContext context, String roomId) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxHeight: 450),
    builder: (context) {
      return ParentSpaceList(roomId: roomId);
    },
  );
}

class ParentSpaceList extends ConsumerWidget {
  final String roomId;

  const ParentSpaceList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentSpaceListData = ref.watch(parentIdsProvider(roomId));
    return parentSpaceListData.when(
      data: (spaceList) => spaceListUI(context, spaceList),
      error: (e, s) {
        _log.severe('Failed to load space', e, s);
        return Text(L10n.of(context).errorLoadingSpaces(e));
      },
      loading:
          () => const Skeletonizer(child: SizedBox(height: 100, width: 100)),
    );
  }

  Widget spaceListUI(BuildContext context, List<String> spaceList) {
    return Column(
      children: [
        Text(
          L10n.of(context).parentSpaces,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: spaceList.length,
            itemBuilder: (context, index) {
              final roomId = spaceList[index];
              return RoomCard(
                key: Key('limited-space-list-item-$roomId'),
                roomId: roomId,
                showParents: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
