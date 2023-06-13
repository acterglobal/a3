import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<ProfileData> getSpaceProfileData(Space space) async {
  // FIXME: how to get informed about updates!?!
  final profile = space.getProfile();
  DispName name = await profile.getDisplayName();
  final displayName = name.text();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName, null);
  }
  final avatar = await profile.getAvatar();
  return ProfileData(displayName, avatar);
}

final spaceProfileDataProvider =
    FutureProvider.family<ProfileData, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(clientProvider)!;
  final space = await client.getSpace(roomIdOrAlias);
  return await getSpaceProfileData(space);
});

final spacesProvider = FutureProvider<List<Space>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final spaces = await client.spaces();
  return spaces.toList();
});

class SpaceItem {
  String roomId;
  ProfileData spaceProfileData;
  List<Member> activeMembers;

  SpaceItem({
    required this.roomId,
    required this.activeMembers,
    required this.spaceProfileData,
  });
}

final spaceItemsProvider = FutureProvider<List<SpaceItem>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final spaces = await client.spaces();
  List<SpaceItem> items = [];
  for (final space in spaces.toList()) {
    FfiListMember members = await space.activeMembers();
    final profile = await getSpaceProfileData(space);
    var item = SpaceItem(
      roomId: space.getRoomId().toString(),
      activeMembers: members.toList(),
      spaceProfileData: profile,
    );
    items.add(item);
  }
  return items;
});

final spaceProvider =
    FutureProvider.family<Space, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: fallback to fetching a public data, if not found
  return await client.getSpace(roomIdOrAlias);
});

final spaceMembersProvider =
    FutureProvider.family<List<Member>, String>((ref, roomIdOrAlias) async {
  final space = ref.watch(spaceProvider(roomIdOrAlias)).requireValue;
  final members = await space.activeMembers();
  return members.toList();
});

final spaceRelationsProvider =
    FutureProvider.family<SpaceRelations, String>((ref, spaceId) async {
  final space = ref.watch(spaceProvider(spaceId)).requireValue;
  return await space.spaceRelations();
});

final spaceEventsProvider =
    FutureProvider.family<List<CalendarEvent>, String>((ref, spaceId) async {
  final space = ref.watch(spaceProvider(spaceId)).requireValue;
  return (await space.calendarEvents()).toList();
});

final canonicalParentProvider =
    FutureProvider.family<SpaceWithProfileData?, String>((ref, spaceId) async {
  final relations = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  final parent = relations.mainParent();
  if (parent == null) {
    debugPrint('no parent');
    return null;
  }

  final client = ref.watch(clientProvider)!;
  final parentSpace = await client.getSpace(parent.roomId().toString());
  final profile = await getSpaceProfileData(parentSpace);
  return SpaceWithProfileData(parentSpace, profile);
});

final relatedSpacesProvider =
    FutureProvider.family<List<SpaceItem>, String>((ref, spaceId) async {
  final client = ref.watch(clientProvider)!;
  final parent = await client.getSpace(spaceId);
  final relatedSpaces = await parent.spaceRelations();
  List<SpaceItem> items = [];
  for (final related in relatedSpaces.children()) {
    String targetType = related.targetType();
    if (targetType != 'ChatRoom') {
      final roomId = related.roomId().toString();
      final child = await client.getSpace(roomId);
      FfiListMember members = await child.activeMembers();
      final profile = await getSpaceProfileData(child);
      var item = SpaceItem(
        roomId: roomId,
        activeMembers: members.toList(),
        spaceProfileData: profile,
      );
      items.add(item);
    }
  }
  return items;
});
