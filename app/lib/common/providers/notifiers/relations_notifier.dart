import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show SpaceHierarchyRoomInfo;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HasSubSpacesNotifier extends FamilyAsyncNotifier<bool, String> {
  late ProviderSubscription<AsyncValue<List<SpaceHierarchyRoomInfo>>> listener;

  @override
  FutureOr<bool> build(String arg) async {
    final spaceId = arg;
    final relatedSpaces = await ref.watch(
      spaceRelationsOverviewProvider(spaceId).future,
    );
    if (relatedSpaces.knownSubspaces.isNotEmpty) {
      return true; // we have subspaces and know it
    }
    if (relatedSpaces.hasMore) {
      // there might be some, but we need to confirm remotely. We do that without blocking
      listener = ref.listen(remoteSubspaceRelationsProvider(spaceId), (
        previous,
        next,
      ) {
        state = next.whenData((data) => data.isNotEmpty);
      });
    }
    return false; // until confirmed, we assume no
  }
}

class HasSubChatsNotifier extends FamilyAsyncNotifier<bool, String> {
  late ProviderSubscription<AsyncValue<List<SpaceHierarchyRoomInfo>>> listener;

  @override
  FutureOr<bool> build(String arg) async {
    final spaceId = arg;
    final relatedSpaces = await ref.watch(
      spaceRelationsOverviewProvider(spaceId).future,
    );
    if (relatedSpaces.knownChats.isNotEmpty) {
      return true; // we have subspaces and know it
    }
    if (relatedSpaces.hasMore) {
      // there might be some, but we need to confirm remotely. We do that without blocking
      listener = ref.listen(remoteChatRelationsProvider(spaceId), (
        previous,
        next,
      ) {
        state = next.whenData((data) => data.isNotEmpty);
      });
    }
    return false; // until confirmed, we assume no
  }
}
