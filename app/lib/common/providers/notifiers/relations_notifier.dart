import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HasSubSpacesNotifier extends FamilyAsyncNotifier<bool, String> {
  @override
  FutureOr<bool> build(String spaceId) async {
    final relatedSpaces =
        await ref.watch(spaceRelationsOverviewProvider(spaceId).future);
    if (relatedSpaces.knownSubspaces.isNotEmpty) {
      return true; // we have subspaces and know it
    }
    if (relatedSpaces.hasMoreSubspaces) {
      // there might be some, but we need to confirm remotely. We do that without blocking
      ref.listen(remoteSubspaceRelationsProvider(spaceId), (previous, next) {
        state = next.whenData((data) => data.isNotEmpty);
      });
    }
    return false; // until confirmed, we assume no
  }
}

class HasSubChatsNotifier extends FamilyAsyncNotifier<bool, String> {
  @override
  FutureOr<bool> build(String spaceId) async {
    final relatedSpaces =
        await ref.watch(spaceRelationsOverviewProvider(spaceId).future);
    if (relatedSpaces.knownChats.isNotEmpty) {
      return true; // we have subspaces and know it
    }
    if (relatedSpaces.hasMoreChats) {
      // there might be some, but we need to confirm remotely. We do that without blocking
      ref.listen(remoteChatRelationsProvider(spaceId), (previous, next) {
        state = next.whenData((data) => data.isNotEmpty);
      });
    }
    return false; // until confirmed, we assume no
  }
}
