import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RoomQuery = ({String parentId, String childId});

final isLinkedProvider = StateProvider.family<bool, RoomQuery>((ref, query) {
  final spaceRel =
      ref.watch(spaceRelationsOverviewProvider(query.parentId)).valueOrNull;
  if (spaceRel == null) {
    return false;
  }

  return spaceRel.knownChats.contains(query.childId) ||
      spaceRel.knownSubspaces.contains(query.childId) ||
      spaceRel.otherRelations
          .map((x) => x.getRoomIdStr())
          .contains(query.childId);
});
