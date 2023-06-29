import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/notifiers/space_profile_notifier.dart';

final spaceProfileDataProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceProfileDataNotifier, ProfileData, Space>(
  () => AsyncSpaceProfileDataNotifier(),
);

final spacesProvider =
    AsyncNotifierProvider.autoDispose<AsyncSpacesNotifier, List<Space>>(
  () => AsyncSpacesNotifier(),
);

final spaceProvider =
    AsyncNotifierProvider.autoDispose.family<AsyncSpaceNotifier, Space, String>(
  () => AsyncSpaceNotifier(),
);

final spaceMembershipProvider =
    FutureProvider.autoDispose.family<Member, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return await space.getMyMembership();
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

final spaceMembersProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, roomIdOrAlias) async {
  final space = await ref.watch(spaceProvider(roomIdOrAlias).future);
  final members = await space.activeMembers();
  return members.toList();
});

final spaceRelationsProvider = FutureProvider.autoDispose
    .family<SpaceRelations, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return await space.spaceRelations();
});

final spaceEventsProvider = FutureProvider.autoDispose
    .family<List<CalendarEvent>, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return (await space.calendarEvents()).toList();
});

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
