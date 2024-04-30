/// Get the relations of the given SpaceId.  Throws
library;

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::room_providers');

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
  try {
    final avatar = (await profile.getAvatar(null)).data();
    _log.info('$roomId : hasAvatar: ${avatar != null}');
    return ProfileData(displayName.text(), avatar);
  } catch (error) {
    _log.severe('Loading avatar for $roomId failed', error);
    return ProfileData(displayName.text(), null);
  }
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

final roomSearchValueProvider =
    StateProvider.autoDispose<String?>((ref) => null);

typedef _RoomIdAndName = (String, String?);

final _briefGroupChatsWithName =
    FutureProvider.autoDispose<List<_RoomIdAndName>>((ref) async {
  final chatList =
      ref.watch(chatsProvider).where((element) => (!element.isDm())).toList();

  List<_RoomIdAndName> items = [];
  for (final convo in chatList) {
    final roomId = convo.getRoomIdStr();
    final room = await ref.watch(maybeRoomProvider(roomId).future);

    if (room != null) {
      final profile = room.getProfile();
      OptionString displayName = await profile.getDisplayName();
      items.add((roomId, displayName.text()));
    }
  }
  return items;
});

final roomSearchedChatsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final allRoomList = await ref.watch(_briefGroupChatsWithName.future);
  final foundRooms = List<String>.empty(growable: true);
  final searchValue = ref.watch(roomSearchValueProvider);

  if (searchValue == null || searchValue.isEmpty) {
    return allRoomList.map((i) {
      return i.$1;
    }).toList();
  }

  final loweredSearchValue = searchValue.toLowerCase();

  for (final item in allRoomList) {
    if (item.$1.toLowerCase().contains(loweredSearchValue) ||
        (item.$2 ?? '').toLowerCase().contains(loweredSearchValue)) {
      foundRooms.add(item.$1);
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
    final SpaceWithProfileData data = (space: parentSpace, profile: profile);
    return data;
  } catch (e) {
    _log.warning('Failed to load canonical parent for $roomId');
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
    FutureProvider.autoDispose.family<Member?, String>(
  (ref, roomId) async {
    final room = await ref.watch(maybeRoomProvider(roomId).future);
    if (room == null || !room.isJoined()) {
      return null;
    }
    return await room.getMyMembership();
  },
);

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
  final status = await ref.watch(roomNotificationStatusProvider(roomId).future);
  return status == 'muted';
});

class RoomNotFound extends Error {}

final roomMemberProvider = FutureProvider.autoDispose
    .family<MemberWithProfile, MemberInfo>((ref, query) async {
  final sdk = await ref.watch(sdkProvider.future);
  final room = await ref.watch(maybeRoomProvider(query.roomId).future);
  if (room == null) {
    throw RoomNotFound;
  }
  final member = await room.getMember(query.userId);
  final profile = member.getProfile();
  final displayName = profile.getDisplayName();
  if (!profile.hasAvatar()) {
    return (member: member, profile: ProfileData(displayName, null));
  }
  final size = sdk.api.newThumbSize(48, 48);
  final avatar = await profile.getAvatar(size);
  return (member: member, profile: ProfileData(displayName, avatar.data()));
});

final membersIdsProvider =
    FutureProvider.family<List<String>, String>((ref, roomIdOrAlias) async {
  final room = await ref.watch(maybeRoomProvider(roomIdOrAlias).future);
  if (room == null) {
    throw RoomNotFound;
  }
  final members = await room.activeMembersIds();
  return asDartStringList(members);
});
