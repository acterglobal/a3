import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/notifiers/space_profile_notifier.dart';
import 'package:logging/logging.dart';

final log = Logger('SpaceProviders');

/// Provider the profile data of a the given space, keeps up to date with underlying client
final spaceProfileDataProvider = AsyncNotifierProvider.family<
    AsyncSpaceProfileDataNotifier, ProfileData, Space>(
  () => AsyncSpaceProfileDataNotifier(),
);

/// Provider a list of the users Space(s), keeps up to date with underlying client
final spacesProvider = AsyncNotifierProvider<AsyncSpacesNotifier, List<Space>>(
  () => AsyncSpacesNotifier(),
);

/// Map a spaceId to the space, keeps up to date with underlying client
/// throws is the space isn't found.
final spaceProvider =
    FutureProvider.family<Space, String>((ref, spaceId) async {
  final maybeSpace = await ref.watch(maybeSpaceProvider(spaceId).future);
  if (maybeSpace != null) {
    return maybeSpace;
  }
  throw 'Space not found';
});

/// Attempts to map a spaceId to the space, but could come back empty (null) rather than throw.
/// keeps up to date with underlying client even if the space wasn't found initially,
final maybeSpaceProvider =
    AsyncNotifierProvider.family<AsyncMaybeSpaceNotifier, Space?, String>(
  () => AsyncMaybeSpaceNotifier(),
);

/// Get the user's membership for a specific space based off the spaceId
/// will throw if the client doesn't kow the space
final spaceMembershipProvider =
    FutureProvider.autoDispose.family<Member?, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  if (!space.isJoined()) {
    return null;
  }
  return await space.getMyMembership();
});

/// Get the SpaceItem of a spaceId or null if the space wasn't found. Keeps up to
/// date with the underlying client even if the space wasn't found initially.
final maybeSpaceInfoProvider =
    FutureProvider.autoDispose.family<SpaceItem?, String>((ref, spaceId) async {
  final space = await ref.watch(maybeSpaceProvider(spaceId).future);
  if (space == null || !space.isJoined()) {
    return null;
  }
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  return SpaceItem(
    space: space,
    roomId: space.getRoomId().toString(),
    membership: await space.getMyMembership(),
    activeMembers: [],
    spaceProfileData: profileData,
  );
});

/// gives current context space id
final selectedSpaceIdProvider = StateProvider<String?>((ref) => null);

/// gives current context space details based on id, will throw null if id is null
final selectedSpaceDetailsProvider =
    FutureProvider.autoDispose<SpaceItem?>((ref) async {
  final selectedSpaceId = ref.watch(selectedSpaceIdProvider);
  if (selectedSpaceId == null) {
    return null;
  }

  final spaces = await ref.watch(briefSpaceItemsProviderWithMembership.future);
  return spaces.firstWhere((element) => element.roomId == selectedSpaceId);
});

// gives current context parent space id
final parentSpaceProvider = StateProvider<String?>((ref) => null);

/// gives current context parent space details based on id, will throw null if id is null
final parentSpaceDetailsProvider =
    FutureProvider.autoDispose<SpaceItem?>((ref) async {
  final parentSpaceId = ref.watch(parentSpaceProvider);
  if (parentSpaceId == null) {
    return null;
  }

  final spaces = await ref.watch(briefSpaceItemsProviderWithMembership.future);
  return spaces.firstWhere((element) => element.roomId == parentSpaceId);
});

class SpaceItem {
  final Member? membership;
  final Space? space;
  final String roomId;
  final ProfileData spaceProfileData;
  final List<Member> activeMembers;

  const SpaceItem({
    this.membership,
    this.space,
    required this.roomId,
    required this.activeMembers,
    required this.spaceProfileData,
  });
}

class SpaceRelationsOverview {
  bool hasMoreSubspaces;
  bool hasMoreChats;
  SpaceRelations rel;
  Member? membership;
  List<Space> knownSubspaces;
  List<Convo> knownChats;
  List<Space> formerlyKnownSubspaces;
  List<Convo> formerlyKnownChats;
  Space? mainParent;
  List<Space> parents;
  List<Space> otherRelations;

  SpaceRelationsOverview({
    required this.rel,
    required this.membership,
    required this.knownSubspaces,
    required this.knownChats,
    required this.formerlyKnownSubspaces,
    required this.formerlyKnownChats,
    required this.mainParent,
    required this.parents,
    required this.otherRelations,
    required this.hasMoreSubspaces,
    required this.hasMoreChats,
  });
}

/// Whether the user has at least one space, where they have the requested permission
final hasSpaceWithPermissionProvider =
    FutureProvider.family.autoDispose<bool, String>((ref, permission) async {
  final spaces = await ref.watch(spacesProvider.future);
  for (final element in spaces) {
    final membership = await element.getMyMembership();
    if (membership.canString(permission)) {
      return true;
    }
  }
  // none found
  return false;
});

/// Get the list of known spaces as SpaceItem filled in brief form
/// (only spaceProfileData, no activeMembers) but with user membership attached.
/// Stays up to date with underlying client info
final briefSpaceItemsProviderWithMembership =
    FutureProvider.autoDispose<List<SpaceItem>>((ref) async {
  final spaces = await ref.watch(spacesProvider.future);
  List<SpaceItem> items = [];
  for (final element in spaces) {
    final profileData =
        await ref.watch(spaceProfileDataProvider(element).future);
    var item = SpaceItem(
      roomId: element.getRoomId().toString(),
      membership: await element.getMyMembership(),
      activeMembers: [],
      spaceProfileData: profileData,
    );
    items.add(item);
  }
  return items;
});

/// Get the SpaceItem of the given sapceId filled in brief form
/// (only spaceProfileData, no activeMembers). Stays up to date with underlying
/// client info
final briefSpaceItemProvider =
    FutureProvider.autoDispose.family<SpaceItem?, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  return SpaceItem(
    roomId: space.getRoomId().toString(),
    membership: null,
    activeMembers: [],
    spaceProfileData: profileData,
  );
});

/// Get the SpaceItem of the given sapceId filled in brief form
/// (only spaceProfileData, no activeMembers) with Membership.
/// Stays up to date with underlying client info
final briefSpaceItemWithMembershipProvider =
    FutureProvider.autoDispose.family<SpaceItem, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  return SpaceItem(
    roomId: space.getRoomId().toString(),
    space: space,
    membership: space.isJoined() ? await space.getMyMembership() : null,
    activeMembers: [],
    spaceProfileData: profileData,
  );
});

/// Fetch the SpaceItems of spaces the user knows about, including profileData,
/// and activeMembers (but without Membership). Stays up to date with underlying
/// client info.
final spaceItemsProvider =
    FutureProvider.autoDispose<List<SpaceItem>>((ref) async {
  final spaces = await ref.watch(spacesProvider.future);
  List<SpaceItem> items = [];
  for (final element in spaces) {
    final profileData = await ref.watch(
      spaceProfileDataProvider(element).future,
    );
    late List<Member> members;
    if (element.isJoined()) {
      members = (await element.activeMembers()).toList();
    } else {
      members = [];
    }
    var item = SpaceItem(
      roomId: element.getRoomId().toString(),
      activeMembers: members,
      spaceProfileData: profileData,
    );
    items.add(item);
  }
  return items;
});

/// Get the active members of a given roomId the user knows about. Errors
/// if the space isn't found. Stays up to date with underlying client data
/// if a space was found.
final spaceMembersProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, roomIdOrAlias) async {
  final space = await ref.watch(spaceProvider(roomIdOrAlias).future);
  if (!space.isJoined()) {
    return [];
  }
  final members = await space.activeMembers();
  return members.toList();
});

/// Get the members invited of a given roomId the user knows about. Errors
/// if the space isn't found. Stays up to date with underlying client data
/// if a space was found.
final spaceInvitedMembersProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, roomIdOrAlias) async {
  final space = await ref.watch(spaceProvider(roomIdOrAlias).future);
  if (!space.isJoined()) {
    return [];
  }
  final members = await space.invitedMembers();
  return members.toList();
});

/// Get the relations of the given SpaceId.  Throws
/// if the space isn't found. Stays up to date with underlying client data
/// if a space was found.
final spaceRelationsProvider = FutureProvider.autoDispose
    .family<SpaceRelations?, String>((ref, spaceId) async {
  final space = await ref.watch(maybeSpaceProvider(spaceId).future);
  if (space == null) {
    return null;
  }
  return await space.spaceRelations();
});

/// Get the canonical parent of the space. Errors if the space isn't found. Stays up
/// to date with underlying client data if a space was found.
final canonicalParentProvider = FutureProvider.autoDispose
    .family<SpaceWithProfileData?, String>((ref, spaceId) async {
  try {
    final relations = await ref.watch(spaceRelationsProvider(spaceId).future);
    if (relations == null) {
      return null;
    }
    final parent = relations.mainParent();
    if (parent == null) {
      debugPrint('no parent');
      return null;
    }

    final parentSpace =
        await ref.watch(spaceProvider(parent.roomId().toString()).future);
    final profile =
        await ref.watch(spaceProfileDataProvider(parentSpace).future);
    return SpaceWithProfileData(parentSpace, profile);
  } catch (e) {
    log.warning('Failed to load canonical parent for $spaceId');
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

/// Get the SpaceRelationsOverview of related SpaceItem for the space. Errors if
/// the space or any related space isn't found. Stays up  to date with underlying
/// client data if a space was found.
final spaceRelationsOverviewProvider = FutureProvider.autoDispose
    .family<SpaceRelationsOverview, String>((ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  if (relatedSpaces == null) {
    throw 'Space not found';
  }
  final membership = await ref.watch(spaceMembershipProvider(spaceId).future);
  bool hasMoreSubspaces = false;
  bool hasMoreChats = false;
  final List<Space> knownSubspaces = [];
  final List<Space> formerlyKnownSubspaces = [];
  final List<Convo> knownChats = [];
  final List<Convo> formerlyKnownChats = [];
  List<Space> otherRelated = [];
  for (final related in relatedSpaces.children()) {
    String targetType = related.targetType();
    final roomId = related.roomId().toString();
    if (targetType == 'ChatRoom') {
      try {
        final chat = await ref.watch(chatProvider(roomId).future);
        if (!chat.isJoined()) {
          formerlyKnownChats.add(chat);
          continue;
        }
        knownChats.add(chat);
      } catch (e) {
        hasMoreChats = true;
      }
    } else {
      try {
        final space = await ref.watch(spaceProvider(roomId).future);
        if (!space.isJoined()) {
          formerlyKnownSubspaces.add(space);
          continue;
        }
        if (await space.isChildSpaceOf(spaceId)) {
          knownSubspaces.add(space);
        } else {
          otherRelated.add(space);
        }
      } catch (e) {
        hasMoreSubspaces = true;
      }
    }
  }
  List<Space> parents = [];

  Space? mainParent;
  final mainSpace = relatedSpaces.mainParent();
  if (mainSpace != null) {
    String targetType = mainSpace.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = mainSpace.roomId().toString();
      try {
        final space = await ref.watch(spaceProvider(roomId).future);
        if (space.isJoined()) {
          mainParent = space;
        }
      } catch (e) {
        debugPrint('Loading main Parent of $spaceId failed: $e');
      }
    }
  }

  for (final related in relatedSpaces.otherParents()) {
    String targetType = related.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = related.roomId().toString();
      try {
        final space = await ref.watch(spaceProvider(roomId).future);
        if (space.isJoined()) {
          parents.add(space);
        }
      } catch (e) {
        debugPrint('Loading other Parents of $spaceId failed: $e');
      }
    }
  }
  return SpaceRelationsOverview(
    rel: relatedSpaces,
    membership: membership,
    parents: parents,
    knownChats: knownChats,
    formerlyKnownChats: formerlyKnownChats,
    knownSubspaces: knownSubspaces,
    formerlyKnownSubspaces: formerlyKnownSubspaces,
    otherRelations: otherRelated,
    mainParent: mainParent,
    hasMoreSubspaces: hasMoreSubspaces,
    hasMoreChats: hasMoreChats,
  );
});

/// Fill the Profile data for the given space-hierarchy-info
final spaceHierarchyProfileProvider = FutureProvider.autoDispose
    .family<ProfileData, SpaceHierarchyRoomInfo>((ref, space) async {
  final client = ref.watch(clientProvider);
  if (client == null) {
    throw 'Client missing';
  }

  final avatar = await space.getAvatar();
  return ProfileData(space.name(), avatar.data());
});
