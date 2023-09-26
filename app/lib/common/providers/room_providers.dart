/// Get the relations of the given SpaceId.  Throws
import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Attempts to map a spaceId to the space, but could come back empty (null) rather than throw.
/// keeps up to date with underlying client even if the space wasn't found initially,
final maybeRoomProvider =
    AsyncNotifierProvider.family<AsyncMaybeRoomNotifier, Room?, String>(
  () => AsyncMaybeRoomNotifier(),
);

/// If the room exists, this returns its space relations
/// Stays up to date with underlying client data if a room was found.
final spaceRelationsProvider = FutureProvider.autoDispose
    .family<SpaceRelations?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  return await room.spaceRelations();
});

/// Get the canonical parent of the space. Errors if the space isn't found. Stays up
/// to date with underlying client data if a space was found.
final canonicalParentProvider = FutureProvider.autoDispose
    .family<SpaceWithProfileData?, String>((ref, roomId) async {
  try {
    final relations = await ref.watch(spaceRelationsProvider(roomId).future);
    if (relations == null) {
      return null;
    }
    final parent = relations.mainParent();
    if (parent == null) {
      return null;
    }

    final parentSpace =
        await ref.watch(maybeSpaceProvider(parent.roomId().toString()).future);
    if (parentSpace == null) {
      return null;
    }
    final profile =
        await ref.watch(spaceProfileDataProvider(parentSpace).future);
    return SpaceWithProfileData(parentSpace, profile);
  } catch (e) {
    log.warning('Failed to load canonical parent for $roomId');
    return null;
  }
});

/// Get the List of related of the spaces for the space. Errors if the space or any
/// related space isn't found. Stays up  to date with underlying client data if
/// a space was found.
final relatedSpacesProvider = FutureProvider.autoDispose
    .family<List<Space>, String>((ref, spaceId) async {
  return (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
      .knownSubspaces;
});
