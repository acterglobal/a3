import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RoomQuery = ({String parentId, String childId});

final isSubChatProvider = StateProvider.family<bool, RoomQuery>(
  (ref, query) =>
      ref
          .watch(spaceRelationsOverviewProvider(query.parentId))
          .valueOrNull
          ?.knownChats
          .contains(query.childId) ==
      true,
);

final isSubSpaceProvider = StateProvider.family<bool, RoomQuery>(
  (ref, query) =>
      ref
          .watch(spaceRelationsOverviewProvider(query.parentId))
          .valueOrNull
          ?.knownSubspaces
          .contains(query.childId) ==
      true,
);

final isRecommendedProvider = StateProvider.family<bool, RoomQuery>(
  (ref, query) =>
      ref
          .watch(spaceRelationsOverviewProvider(query.parentId))
          .valueOrNull
          ?.otherRelations
          .map((x) => x.getRoomIdStr())
          .contains(query.childId) ==
      true,
);
