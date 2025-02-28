import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::actions::limited-space-list');

Future<void> showLimitedSpaceList(BuildContext context, String roomId) async {
  if (!context.mounted) return;
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    constraints: const BoxConstraints(maxHeight: 450),
    isScrollControlled: true,
    builder: (context) {
      return LimitedSpaceList(roomId: roomId);
    },
  );
}

class LimitedSpaceList extends ConsumerWidget {
  final String roomId;

  const LimitedSpaceList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitedSpaceIdsData = ref.watch(
      joinRulesAllowedRoomsProvider(roomId),
    );
    return limitedSpaceIdsData.when(
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
          L10n.of(context).spaceWithAccess,
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
