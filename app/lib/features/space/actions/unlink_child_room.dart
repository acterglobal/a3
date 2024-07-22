import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> unlinkChildRoom(
  BuildContext context,
  WidgetRef ref, {
  required String parentId,
  required String roomId,
  String? reason,
}) async {
  reason = reason ?? L10n.of(context).unlinkRoom;
  //Fetch selected parent space data and add given roomId as child
  final space = await ref.read(spaceProvider(parentId).future);
  if (!context.mounted) return;
  await space.removeChildRoom(roomId, reason);
  //Fetch selected room data and add given parentSpaceId as parent
  final room = await ref.read(maybeRoomProvider(roomId).future);
  if (room != null && room.isSpace()) {
    await room.removeParentRoom(parentId, reason);
  }
  // spaceRelations come from the server and must be manually invalidated
  ref.invalidate(spaceRelationsOverviewProvider(parentId));
}
