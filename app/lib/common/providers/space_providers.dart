import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/notifiers/space_profile_notifier.dart';

/// Provider the profile data of a the given space, keeps up to date with underlying client
final spaceProfileDataProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceProfileDataNotifier, ProfileData, Space>(
  () => AsyncSpaceProfileDataNotifier(),
);

/// Provider a list of the users Space(s), keeps up to date with underlying client
final spacesProvider =
    AsyncNotifierProvider.autoDispose<AsyncSpacesNotifier, List<Space>>(
  () => AsyncSpacesNotifier(),
);

/// Map a spaceId to the space, keeps up to date with underlying client
/// throws is the space isn't found.
final spaceProvider =
    AsyncNotifierProvider.autoDispose.family<AsyncSpaceNotifier, Space, String>(
  () => AsyncSpaceNotifier(),
);

/// Attempts to map a spaceId to the space, but could come back empty (null) rather than throw.
/// keeps up to date with underlying client even if the space wasn't found initially,
final maybeSpaceProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncMaybeSpaceNotifier, Space?, String>(
  () => AsyncMaybeSpaceNotifier(),
);

/// Get the user's membership for a specific space based off the spaceId
/// will throw if the client doesn't kow the space
final spaceMembershipProvider =
    FutureProvider.autoDispose.family<Member, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return await space.getMyMembership();
});

/// Get the SpaceItem of a spaceId or null if the space wasn't found. Keeps up to
/// date with the underlying client even if the space wasn't found initially.
final maybeSpaceInfoProvider =
    FutureProvider.autoDispose.family<SpaceItem?, String>((ref, spaceId) async {
  final space = await ref.watch(maybeSpaceProvider(spaceId).future);
  if (space == null) {
    // we are doing a cheeky on here and assume that means, we aren't a member
    return null;
  }
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  return SpaceItem(
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
  Member? membership;
  String roomId;
  ProfileData spaceProfileData;
  List<Member> activeMembers;

  SpaceItem({
    this.membership,
    required this.roomId,
    required this.activeMembers,
    required this.spaceProfileData,
  });
}

class SpaceRelationsOverview {
  Member? membership;
  List<SpaceItem> children;
  SpaceItem? mainParent;
  List<SpaceItem> parents;
  List<SpaceItem> otherRelations;

  SpaceRelationsOverview({
    required this.membership,
    required this.children,
    required this.mainParent,
    required this.parents,
    required this.otherRelations,
  });
}

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

/// Get the list of known spaces as SpaceItem filled in brief form
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

/// Fetch the SpaceItems of spaces the user knows about, including profileData,
/// and activeMembers (but without Membership). Stays up to date with underlying
/// client info.
final spaceItemsProvider =
    FutureProvider.autoDispose<List<SpaceItem>>((ref) async {
  final spaces = await ref.watch(spacesProvider.future);
  List<SpaceItem> items = [];
  for (final element in spaces) {
    List<Member> members =
        await element.activeMembers().then((ffiList) => ffiList.toList());
    final profileData =
        await ref.watch(spaceProfileDataProvider(element).future);
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
  final members = await space.activeMembers();
  return members.toList();
});

/// Get the relations of the given SpaceId.  Throws
/// if the space isn't found. Stays up to date with underlying client data
/// if a space was found.
final spaceRelationsProvider = FutureProvider.autoDispose
    .family<SpaceRelations, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return await space.spaceRelations();
});

// final spaceEventsProvider = FutureProvider.autoDispose
//     .family<List<CalendarEvent>, String>((ref, spaceId) async {
//   final space = await ref.watch(spaceProvider(spaceId).future);
//   return (await space.calendarEvents()).toList();
// });

/// Get the canonical parent of the space. Errors if the space isn't found. Stays up
/// to date with underlying client data if a space was found.
final canonicalParentProvider = FutureProvider.autoDispose
    .family<SpaceWithProfileData?, String>((ref, spaceId) async {
  final relations = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  final parent = relations.mainParent();
  if (parent == null) {
    debugPrint('no parent');
    return null;
  }

  final parentSpace =
      await ref.watch(spaceProvider(parent.roomId().toString()).future);
  final profile = await ref.watch(spaceProfileDataProvider(parentSpace).future);
  return SpaceWithProfileData(parentSpace, profile);
});

/// Get the List of related of the spaces for the space. Errors if the space or any
/// related space isn't found. Stays up  to date with underlying client data if
/// a space was found.
final relatedSpacesProvider = FutureProvider.autoDispose
    .family<List<Space>, String>((ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  final spaces = [];
  for (final related in relatedSpaces.children()) {
    String targetType = related.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = related.roomId().toString();
      final space = await ref.watch(spaceProvider(roomId).future);
      spaces.add(space);
    }
  }
  return List<Space>.from(spaces);
});

/// Get the SpaceRelationsOverview of related SpaceItem for the space. Errors if
/// the space or any related space isn't found. Stays up  to date with underlying
/// client data if a space was found.
final relatedSpaceItemsProvider = FutureProvider.autoDispose
    .family<SpaceRelationsOverview, String>((ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  final membership = await ref.watch(spaceMembershipProvider(spaceId).future);
  List<SpaceItem> children = [];
  List<SpaceItem> otherRelated = [];
  for (final related in relatedSpaces.children()) {
    String targetType = related.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = related.roomId().toString();
      final space = await ref.watch(spaceProvider(roomId).future);

      List<Member> members =
          await space.activeMembers().then((ffiList) => ffiList.toList());
      final profileData =
          await ref.watch(spaceProfileDataProvider(space).future);
      var item = SpaceItem(
        roomId: space.getRoomId().toString(),
        activeMembers: members,
        spaceProfileData: profileData,
      );
      if (await space.isChildSpaceOf(spaceId)) {
        children.add(item);
      } else {
        otherRelated.add(item);
      }
    }
  }
  List<SpaceItem> parents = [];

  SpaceItem? mainParent;
  final mainSpace = relatedSpaces.mainParent();
  if (mainSpace != null) {
    String targetType = mainSpace.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = mainSpace.roomId().toString();
      final space = await ref.watch(spaceProvider(roomId).future);

      List<Member> members =
          await space.activeMembers().then((ffiList) => ffiList.toList());
      final profileData =
          await ref.watch(spaceProfileDataProvider(space).future);
      mainParent = SpaceItem(
        roomId: space.getRoomId().toString(),
        activeMembers: members,
        spaceProfileData: profileData,
      );
    }
  }

  for (final related in relatedSpaces.otherParents()) {
    String targetType = related.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = related.roomId().toString();
      final space = await ref.watch(spaceProvider(roomId).future);

      List<Member> members =
          await space.activeMembers().then((ffiList) => ffiList.toList());
      final profileData =
          await ref.watch(spaceProfileDataProvider(space).future);
      var item = SpaceItem(
        roomId: space.getRoomId().toString(),
        activeMembers: members,
        spaceProfileData: profileData,
      );
      parents.add(item);
    }
  }
  return SpaceRelationsOverview(
    membership: membership,
    parents: parents,
    children: children,
    otherRelations: otherRelated,
    mainParent: mainParent,
  );
});
