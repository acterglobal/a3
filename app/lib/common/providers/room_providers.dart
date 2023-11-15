/// Get the relations of the given SpaceId.  Throws
import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/chat_providers.dart';

class RoomItem {
  final Member? membership;
  final Room? room;
  final String roomId;
  final ProfileData roomProfileData;
  final List<Member> activeMembers;

  const RoomItem({
    this.membership,
    this.room,
    required this.roomId,
    required this.activeMembers,
    required this.roomProfileData,
  });
}

/// Attempts to map a roomId to the room, but could come back empty (null) rather than throw.
/// keeps up to date with underlying client even if the room wasn't found initially,
final maybeRoomProvider =
    AsyncNotifierProvider.family<AsyncMaybeRoomNotifier, Room?, String>(
  () => AsyncMaybeRoomNotifier(),
);

/// Provider the profile data of a the given room, keeps up to date with underlying client
final roomProfileDataProvider =
    FutureProvider.autoDispose.family<ProfileData, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    throw 'Room $roomId not found';
  }

  final profile = room.getProfile();
  OptionString displayName = await profile.getDisplayName();
  final avatar = await profile.getAvatar();
  return ProfileData(displayName.text(), avatar.data());
});

/// Get the members invited of a given roomId the user knows about. Errors
/// if the room isn't found. Stays up to date with underlying client data
/// if a room was found.
final roomInvitedMembersProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, roomIdOrAlias) async {
  final room = await ref.watch(maybeRoomProvider(roomIdOrAlias).future);
  if (room == null || !room.isJoined()) {
    return [];
  }
  final members = await room.invitedMembers();
  return members.toList();
});

/// Get the RoomItem of the given sapceId filled in brief form
/// (only spaceProfileData, no activeMembers) with Membership.
/// Stays up to date with underlying client info
final briefRoomItemWithMembershipProvider =
    FutureProvider.autoDispose.family<RoomItem, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    throw 'Room $roomId not found';
  }
  final profileData = await ref.watch(roomProfileDataProvider(roomId).future);
  return RoomItem(
    roomId: room.roomIdStr(),
    room: room,
    membership: room.isJoined() ? await room.getMyMembership() : null,
    activeMembers: [],
    roomProfileData: profileData,
  );
});

final briefRoomItemsWithMembershipProvider = FutureProvider.autoDispose<List<RoomItem>>((ref) async {
  final chatList = ref.watch(chatsProvider).where((element) => (!element.isDm())).toList();

  List<RoomItem> items = [];
  for (final element in chatList) {
    final room = await ref.watch(maybeRoomProvider(element.getRoomIdStr()).future);
    if (room == null) {
      throw 'Room ${element.getRoomIdStr()} not found';
    }
    final profileData = await ref.watch(roomProfileDataProvider(element.getRoomIdStr()).future);

    final item = RoomItem(
      roomId: room.roomIdStr(),
      room: room,
      membership: room.isJoined() ? await room.getMyMembership() : null,
      activeMembers: [],
      roomProfileData: profileData,
    );
    items.add(item);
  }
  return items;
});

final roomSearchedChatsProvider = FutureProvider.autoDispose<List<RoomItem>>((ref) async {
  final allRooms = ref.watch(chatsProvider).where((element) => (!element.isDm())).toList();
  final searchValue = ref.watch(chatSearchValueProvider);
  final foundRooms = List<RoomItem>.empty(growable: true);

  for (final element in allRooms) {
    final room = await ref.watch(maybeRoomProvider(element.getRoomIdStr()).future);
    if (room == null) {
      throw 'Room ${element.getRoomIdStr()} not found';
    }

    final profileData = await ref.watch(roomProfileDataProvider(element.getRoomIdStr()).future);
    final name = profileData.displayName ?? element.getRoomIdStr();

    if (name.toLowerCase().contains(searchValue!.toLowerCase())) {
      final item = RoomItem(
        roomId: room.roomIdStr(),
        room: room,
        membership: room.isJoined() ? await room.getMyMembership() : null,
        activeMembers: [],
        roomProfileData: profileData,
      );
      foundRooms.add(item);
    }
  }
  return foundRooms;
});

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

/// Get the user's membership for a specific space based off the spaceId
/// will throw if the client doesn't kow the space
final roomMembershipProvider =
    FutureProvider.autoDispose.family<Member?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null || !room.isJoined()) {
    return null;
  }
  return await room.getMyMembership();
});

/// Get the locally configured RoomNotificationsStatus for this room
final roomNotificationStatusProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  return room.notificationMode();
});

/// Get the default RoomNotificationsStatus for this room type
final roomDefaultNotificationStatusProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  return room.defaultNotificationMode();
});

/// Get the default RoomNotificationsStatus for this room type
final roomIsMutedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, roomId) async {
  return (await ref.watch(roomNotificationStatusProvider(roomId).future)) ==
      'muted';
});
