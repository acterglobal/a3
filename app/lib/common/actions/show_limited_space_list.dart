import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showLimitedSpaceList(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) async {
  final limitedSpaceIds =
      await ref.watch(joinRulesAllowedRoomsProvider(roomId).future);
  if (!context.mounted) return;
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    constraints: const BoxConstraints(maxHeight: 450),
    isScrollControlled: true,
    builder: (context) {
      return _buildLimitedSpaceListUI(context, ref, limitedSpaceIds);
    },
  );
}

Widget _buildLimitedSpaceListUI(
  BuildContext context,
  WidgetRef ref,
  List<String> limitedSpaceIds,
) {
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
          itemCount: limitedSpaceIds.length,
          itemBuilder: (context, index) {
            final roomId = limitedSpaceIds[index];
            return SpaceCard(
              key: Key('limited-space-list-item-$roomId'),
              roomId: roomId,
              showParents: false,
            );
          },
        ),
      ),
    ],
  );
}
