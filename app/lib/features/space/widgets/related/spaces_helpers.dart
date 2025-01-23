import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_hierarchy_join_button.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::related::spaces_helpers');

Widget renderRemoteSubspaces(
  BuildContext context,
  WidgetRef ref,
  String spaceIdOrAlias,
  List<SpaceHierarchyRoomInfo> spaces, {
  int? maxLength,
  EdgeInsetsGeometry? padding,
}) {
  if (spaces.isEmpty) {
    return const SizedBox.shrink();
  }

  int itemCount = spaces.length;
  if (maxLength != null && maxLength < itemCount) {
    itemCount = maxLength;
  }

  return GridView.builder(
    padding: padding,
    itemCount: itemCount,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 1,
      childAspectRatio: 4.0,
      mainAxisExtent: 100,
    ),
    shrinkWrap: true,
    itemBuilder: (context, index) {
      final roomInfo = spaces[index];
      final parentId = spaceIdOrAlias;
      final roomId = roomInfo.roomIdStr();
      return RoomHierarchyCard(
        key: Key('subspace-list-item-$roomId'),
        roomInfo: roomInfo,
        parentId: parentId,
        indicateIfSuggested: true,
        trailing: Wrap(
          children: [
            RoomHierarchyJoinButton(
              joinRule: roomInfo.joinRuleStr().toLowerCase(),
              roomId: roomId,
              roomName: roomInfo.name() ?? roomId,
              viaServerName: roomInfo.viaServerNames().toDart(),
              forward: (spaceId) {
                goToSpace(context, spaceId);
                ref.invalidate(spaceRelationsProvider(parentId));
                ref.invalidate(spaceRemoteRelationsProvider(parentId));
              },
            ),
            RoomHierarchyOptionsMenu(
              isSuggested: roomInfo.suggested(),
              childId: roomId,
              parentId: parentId,
            ),
          ],
        ),
      );
    },
  );
}

Widget renderMoreSubspaces(
  BuildContext context,
  WidgetRef ref,
  String spaceIdOrAlias, {
  int? maxLength,
  EdgeInsetsGeometry? padding,
}) {
  final relatedSpacesLoader =
      ref.watch(remoteSubspaceRelationsProvider(spaceIdOrAlias));
  return relatedSpacesLoader.when(
    data: (spaces) => renderRemoteSubspaces(
      context,
      ref,
      spaceIdOrAlias,
      spaces,
      maxLength: maxLength,
      padding: padding,
    ),
    error: (e, s) {
      _log.severe('Failed to load the related subspaces', e, s);
      return Card(
        child: ListTile(
          title: Text(L10n.of(context).loadingSpacesFailed(e)),
        ),
      );
    },
    loading: () => const Skeletonizer(
      child: Card(
        child: ListTile(title: Text('random text')),
      ),
    ),
  );
}
