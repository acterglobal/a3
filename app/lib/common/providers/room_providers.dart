/// Get the relations of the given SpaceId.  Throws
library;

import 'dart:typed_data';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::room_providers');

class RoomItem {
  final Member? membership;
  final Room? room;
  final String roomId;
  final AvatarInfo avatarInfo;
  final List<Member> activeMembers;

  const RoomItem({
    this.membership,
    this.room,
    required this.roomId,
    required this.activeMembers,
    required this.avatarInfo,
  });
}

class RoomNotFound extends Error {}

/// Attempts to map a roomId to the room, but could come back empty (null) rather than throw.
/// keeps up to date with underlying client even if the room wasn’t found initially,
final maybeRoomProvider =
    AsyncNotifierProvider.family<AsyncMaybeRoomNotifier, Room?, String>(
      () => AsyncMaybeRoomNotifier(),
    );

/// gives current visibility state of space, return empty if no space is found
final roomJoinRuleProvider = FutureProvider.family
    .autoDispose<RoomJoinRule?, String>((ref, roomId) async {
      final room = await ref.watch(maybeRoomProvider(roomId).future);
      if (room == null) return null;
      final joinRule = room.joinRuleStr();
      final visibility = switch (joinRule.toLowerCase()) {
        'public' => RoomJoinRule.Public,
        'restricted' => RoomJoinRule.Restricted,
        'invite' => RoomJoinRule.Invite,
        _ => null,
      };
      if (visibility == null) {
        _log.warning('Unsupported joinRule for $roomId: $joinRule');
        throw 'Unsupported joinRule $joinRule';
      }
      return visibility;
    });

/// Get the members invited of a given roomId the user knows about. Errors
/// if the room isn’t found. Stays up to date with underlying client data
/// if a room was found.
final roomInvitedMembersProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, roomIdOrAlias) async {
      final room = await ref.watch(maybeRoomProvider(roomIdOrAlias).future);
      if (room == null || !room.isJoined()) return [];
      final members = await room.invitedMembers();
      return members.toList();
    });

final roomSearchValueProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

typedef _RoomIdAndName = (String, String?);

final _briefGroupChatsWithName =
    FutureProvider.autoDispose<List<_RoomIdAndName>>((ref) async {
      final chatList =
          ref.watch(chatsProvider).where((element) => !element.isDm()).toList();

      List<_RoomIdAndName> items = [];
      for (final convo in chatList) {
        final roomId = convo.getRoomIdStr();
        final displayName =
            ref.watch(roomDisplayNameProvider(roomId)).valueOrNull;
        items.add((roomId, displayName));
      }
      return items;
    });

final roomSearchedChatsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final allRoomList = await ref.watch(_briefGroupChatsWithName.future);
  final foundRooms = List<String>.empty(growable: true);
  final searchValue = ref.watch(roomSearchValueProvider);

  if (searchValue == null || searchValue.isEmpty) {
    return allRoomList.map((item) {
      final (roomId, dispName) = item;
      return roomId;
    }).toList();
  }

  final loweredSearchValue = searchValue.toLowerCase();

  for (final (roomId, dispName) in allRoomList) {
    if (roomId.toLowerCase().contains(loweredSearchValue) ||
        (dispName ?? '').toLowerCase().contains(loweredSearchValue)) {
      foundRooms.add(roomId);
    }
  }

  return foundRooms;
});

/// If the room exists, this returns its space relations
/// Stays up to date with underlying client data if a room was found.
final spaceRelationsProvider = FutureProvider.family<SpaceRelations?, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) return null;
  return await room.spaceRelations();
});

final parentIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  roomId,
) async {
  try {
    // FIXME: we should get only the parent Ids from the underlying SDK
    final relations = await ref.watch(spaceRelationsProvider(roomId).future);
    if (relations == null) return [];
    // Collect all parents: mainParent and otherParents
    List<String> allParents =
        relations.mainParent().map((p) => [p.roomId().toString()]) ?? [];
    final others = relations.otherParents().map((p) => p.roomId().toString());
    allParents.addAll(others);
    return allParents;
  } catch (e) {
    _log.warning('Failed to load parent ids for $roomId: $e');
    return [];
  }
});

/// Caching the name of each Room
final roomDisplayNameProvider = FutureProvider.family<String?, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) return null;
  return (await room.displayName()).text();
});

/// Caching the MemoryImage of each room
final roomAvatarProvider = FutureProvider.family<MemoryImage?, String>((
  ref,
  roomId,
) async {
  final sdk = await ref.watch(sdkProvider.future);
  final thumbsize = sdk.api.newThumbSize(48, 48);
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null || !room.hasAvatar()) return null;
  final avatar = await room.avatar(thumbsize);
  return avatar.data().map(
    (data) => MemoryImage(Uint8List.fromList(data.asTypedList())),
  );
});

/// Provide the AvatarInfo for each room. Update internally accordingly
final roomAvatarInfoProvider =
    NotifierProvider.family<RoomAvatarInfoNotifier, AvatarInfo, String>(
      () => RoomAvatarInfoNotifier(),
    );

/// get the [AvatarInfo] list of all the parents
final parentAvatarInfosProvider =
    FutureProvider.family<List<AvatarInfo>?, String>((ref, roomId) async {
      final parents = await ref.watch(parentIdsProvider(roomId).future);
      // Filter out parents where we can't get the room
      final validParents =
          parents.where((parent) {
            final room = ref.watch(maybeRoomProvider(parent)).valueOrNull;
            return room != null;
          }).toList();

      // watch each one individually
      return validParents
          .map((e) => ref.watch(roomAvatarInfoProvider(e)))
          .toList();
    });

final joinRulesAllowedRoomsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, roomId) async {
      final room = await ref.watch(maybeRoomProvider(roomId).future);
      if (room == null) return [];
      return asDartStringList(room.restrictedRoomIdsStr());
    });

/// Get the user’s membership for a specific space based off the roomId
/// will not throw if the client doesn’t kow the room
final roomMembershipProvider = FutureProvider.family<Member?, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null || !room.isJoined()) return null;
  return await room.getMyMembership();
});

typedef RoomPermission = ({String roomId, String permission});

/// Get the whether the user has the given permission in the room
final roomPermissionProvider = FutureProvider.family<bool, RoomPermission>((
  ref,
  permission,
) async {
  final membership = await ref.watch(
    roomMembershipProvider(permission.roomId).future,
  );
  return membership?.canString(permission.permission) ?? false;
});

/// Get the locally configured RoomNotificationsStatus for this room
final roomNotificationStatusProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, roomId) async {
      final room = await ref.watch(maybeRoomProvider(roomId).future);
      if (room == null) return null;
      return await room.notificationMode();
    });

/// Get the default RoomNotificationsStatus for this room type
final roomDefaultNotificationStatusProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, roomId) async {
      final room = await ref.watch(maybeRoomProvider(roomId).future);
      if (room == null) return null;
      return await room.defaultNotificationMode();
    });

/// Get the default RoomNotificationsStatus for this room type
final roomIsMutedProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  roomId,
) async {
  final status = await ref.watch(roomNotificationStatusProvider(roomId).future);
  return status == 'muted';
});

final memberProvider = FutureProvider.autoDispose.family<Member, MemberInfo>((
  ref,
  query,
) async {
  final room = await ref.watch(maybeRoomProvider(query.roomId).future);
  if (room == null) throw RoomNotFound;
  return await room.getMember(query.userId);
});

final _memberProfileProvider = FutureProvider.autoDispose
    .family<UserProfile, MemberInfo>((ref, query) async {
      final member = await ref.watch(memberProvider(query).future);
      return member.getProfile();
    });

final membershipStatusStr = FutureProvider.autoDispose
    .family<String, MemberInfo>((ref, query) async {
      final member = await ref.watch(memberProvider(query).future);
      return member.membershipStatusStr();
    });

final memberDisplayNameProvider = FutureProvider.autoDispose
    .family<String?, MemberInfo>((ref, query) async {
      try {
        final profile = ref.watch(_memberProfileProvider(query)).valueOrNull;
        return profile?.displayName();
      } on RoomNotFound {
        return null;
      }
    });

/// Caching the MemoryImage of each room
final memberAvatarProvider = FutureProvider.autoDispose.family<
  MemoryImage?,
  MemberInfo
>((ref, query) async {
  final sdk = await ref.watch(sdkProvider.future);

  final thumbsize = sdk.api.newThumbSize(48, 48);
  try {
    final profile = await ref.watch(_memberProfileProvider(query).future);
    // use .data() consumes the value so we keep it stored, any further call to .data()
    // comes back empty as the data was consumed.
    final avatar = await profile.getAvatar(thumbsize);
    return avatar.data().map(
      (data) => MemoryImage(Uint8List.fromList(data.asTypedList())),
    );
  } on RoomNotFound {
    return null;
  }
});

final memberAvatarInfoProvider = Provider.autoDispose
    .family<AvatarInfo, MemberInfo>((ref, query) {
      final displayName =
          ref.watch(memberDisplayNameProvider(query)).valueOrNull;
      final avatarData = ref.watch(memberAvatarProvider(query)).valueOrNull;

      return AvatarInfo(
        uniqueId: query.userId,
        displayName: displayName,
        avatar: avatarData,
      );
    });

/// Ids of the members of this Room. Returns empty list if the room isn’t found
final membersIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  roomIdOrAlias,
) async {
  final room = await ref.watch(maybeRoomProvider(roomIdOrAlias).future);
  if (room == null) return [];
  final members = await room.activeMembersIds();
  return asDartStringList(members);
});

typedef RoomMembersSearchParam = ({String roomId, String searchValue});

/// Ids of the members of the Room with search value.
/// Returns empty list if the room isn’t found
final membersIdWithSearchProvider = FutureProvider.family
    .autoDispose<List<String>, RoomMembersSearchParam>((ref, param) async {
      final room = await ref.watch(maybeRoomProvider(param.roomId).future);
      if (room == null) return [];
      final members = await room.activeMembersIds();
      final List<String> membersIdList = asDartStringList(members);
      final searchTerm = param.searchValue.toLowerCase();
      if (searchTerm.isEmpty) return membersIdList;

      final List<String> foundedMembersId = [];
      for (final memberId in membersIdList) {
        final memberInfo = ref.watch(
          memberAvatarInfoProvider((userId: memberId, roomId: param.roomId)),
        );
        if (memberInfo.displayName?.toLowerCase().contains(searchTerm) ==
                true ||
            memberId.toLowerCase().contains(searchTerm)) {
          foundedMembersId.add(memberId);
        }
      }
      return foundedMembersId;
    });

//FIXME : This need to be handle from rust side
final isDirectChatProvider = FutureProvider.family<bool, String>((
  ref,
  roomIdOrAlias,
) async {
  final convo = await ref.watch(chatProvider(roomIdOrAlias).future);
  final members = await ref.watch(membersIdsProvider(roomIdOrAlias).future);
  return convo?.isDm() == true && members.length == 2;
});

final isConvoBookmarked = FutureProvider.family<bool, String>((
  ref,
  roomIdOrAlias,
) async {
  final convo = await ref.watch(chatProvider(roomIdOrAlias).future);
  return convo?.isBookmarked() == true;
});

/// Caching the MemoryImage of each entry
final roomHierarchyAvatarProvider =
    FutureProvider.family<MemoryImage?, SpaceHierarchyRoomInfo>((
      ref,
      room,
    ) async {
      final sdk = await ref.watch(sdkProvider.future);
      final thumbsize = sdk.api.newThumbSize(48, 48);
      final avatar = await room.getAvatar(thumbsize);
      return avatar.data().map(
        (data) => MemoryImage(Uint8List.fromList(data.asTypedList())),
      );
    });

/// Fill the Profile data for the given space-hierarchy-info
final roomHierarchyAvatarInfoProvider = Provider.autoDispose.family<
  AvatarInfo,
  SpaceHierarchyRoomInfo
>((ref, info) {
  final roomId = info.roomIdStr();
  final displayName = info.name();

  // final displayName = ref.watch(roomDisplayNameProvider(roomId)).valueOrNull;
  final avatarData = ref.watch(roomHierarchyAvatarProvider(info)).valueOrNull;

  return AvatarInfo(
    uniqueId: roomId,
    displayName: displayName,
    avatar: avatarData,
  );
});
