import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/relations_notifier.dart';
import 'package:acter/common/providers/notifiers/space_notifiers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::space_providers');

/// Provider the list of all spaces, keeps up to date with the order and the underlying client
final spacesProvider =
    StateNotifierProvider<SpaceListNotifier, List<Space>>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return SpaceListNotifier(ref: ref, client: client);
});

final bookmarkedSpacesProvider = Provider(
  (ref) => ref.watch(spacesProvider).where((s) => s.isBookmarked()).toList(),
);

/// List of spaces other than current space and it's parent space
final otherSpacesForInviteMembersProvider = FutureProvider.autoDispose
    .family<List<Space>, String>((ref, spaceId) async {
  //GET LIST OF ALL SPACES
  final allSpaces = ref.watch(spacesProvider);

  //GET PARENT SPACE
  final parentSpaces = ref.watch(parentIdsProvider(spaceId)).valueOrNull;

  //GET LIST OF SPACES EXCLUDING PARENT SPACES && EXCLUDING CURRENT SPACE
  final spacesExcludingParentSpacesAndCurrentSpace = allSpaces.where((space) {
    final roomId = space.getRoomIdStr();
    return !(parentSpaces!.any((p) => p == roomId)) && roomId != spaceId;
  }).toList();

  return spacesExcludingParentSpacesAndCurrentSpace;
});

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

/// Get the SpaceItem of a spaceId or null if the space wasn't found. Keeps up to
/// date with the underlying client even if the space wasn't found initially.
final maybeSpaceInfoProvider =
    FutureProvider.autoDispose.family<SpaceItem?, String>((ref, spaceId) async {
  final space = await ref.watch(maybeSpaceProvider(spaceId).future);
  if (space == null || !space.isJoined()) {
    return null;
  }
  final avatarInfo = ref.watch(roomAvatarInfoProvider(spaceId));
  final membership = await space.getMyMembership();
  return SpaceItem(
    space: space,
    roomId: space.getRoomIdStr(),
    membership: membership,
    activeMembers: [],
    avatarInfo: avatarInfo,
  );
});

/// gives current context space id
final selectedSpaceIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// gives current context space details based on id, will throw null if id is null
final selectedSpaceDetailsProvider =
    FutureProvider.autoDispose<SpaceItem?>((ref) async {
  final selectedSpaceId = ref.watch(selectedSpaceIdProvider);
  if (selectedSpaceId == null) {
    return null;
  }

  return await ref.watch(briefSpaceItemProvider(selectedSpaceId).future);
});

class SpaceItem {
  final Member? membership;
  final Space? space;
  final String roomId;
  final AvatarInfo avatarInfo;
  final List<Member> activeMembers;

  const SpaceItem({
    this.membership,
    this.space,
    required this.roomId,
    required this.activeMembers,
    required this.avatarInfo,
  });
}

class SpaceRelationsOverview {
  bool hasMoreSubspaces;
  bool hasMoreChats;
  SpaceRelations rel;
  Member? membership;
  List<Space> knownSubspaces;
  List<Convo> knownChats;
  List<String> suggestedIds;
  Space? mainParent;
  List<Space> parents;
  List<Space> otherRelations;

  SpaceRelationsOverview({
    required this.rel,
    required this.membership,
    required this.knownSubspaces,
    required this.knownChats,
    required this.suggestedIds,
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
  final spaces = ref.watch(spacesProvider);
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
final _spaceIdAndNames =
    FutureProvider.autoDispose<List<_SpaceIdAndName>>((ref) async {
  final spaces = ref.watch(spacesProvider);
  List<_SpaceIdAndName> items = [];
  for (final space in spaces) {
    final roomId = space.getRoomIdStr();
    items.add(
      (roomId, await ref.watch(roomDisplayNameProvider(roomId).future)),
    );
  }
  return items;
});

class SpaceNotFound extends Error {}

typedef _SpaceIdAndName = (String, String?);

final searchedSpacesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final searchValue = ref.watch(roomSearchValueProvider);
  final allSpaces = await ref.watch(_spaceIdAndNames.future);

  if (searchValue == null || searchValue.isEmpty) {
    return allSpaces
        .map(
          (e) => e.$1,
        )
        .toList();
  }

  final searchTerm = searchValue.toLowerCase();

  final foundSpaces = List<String>.empty(growable: true);

  for (final item in allSpaces) {
    if (item.$1.contains(searchTerm) ||
        (item.$2 != null
            ? item.$2!.toLowerCase().contains(searchTerm)
            : false)) {
      foundSpaces.add(item.$1);
    }
  }

  return foundSpaces;
});

/// Get the SpaceItem of the given sapceId filled in brief form
/// (only spaceProfileData, no activeMembers). Stays up to date with underlying
/// client info
final briefSpaceItemProvider =
    FutureProvider.autoDispose.family<SpaceItem, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  final avatarInfo = ref.watch(roomAvatarInfoProvider(spaceId));
  return SpaceItem(
    roomId: space.getRoomIdStr(),
    membership: null,
    activeMembers: [],
    avatarInfo: avatarInfo,
  );
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

/// Get the SpaceRelationsOverview of related SpaceItem for the space. Errors if
/// the space or any related space isn't found. Stays up  to date with underlying
/// client data if a space was found.
final spaceRelationsOverviewProvider =
    FutureProvider.family<SpaceRelationsOverview, String>((ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  if (relatedSpaces == null) {
    throw SpaceNotFound;
  }
  final membership = await ref.watch(roomMembershipProvider(spaceId).future);
  bool hasMoreSubspaces = false;
  bool hasMoreChats = false;
  final List<Space> knownSubspaces = [];
  final List<Convo> knownChats = [];
  final List<String> suggested = [];
  List<Space> otherRelated = [];
  for (final related in relatedSpaces.children()) {
    String targetType = related.targetType();
    final roomId = related.roomId().toString();
    if (related.suggested()) {
      suggested.add(roomId);
    }
    if (targetType == 'ChatRoom') {
      try {
        final chat = await ref.watch(chatProvider(roomId).future);
        knownChats.add(chat);
      } catch (e) {
        hasMoreChats = true;
      }
    } else {
      try {
        final space = await ref.watch(spaceProvider(roomId).future);
        final isChildSpaceOf = await space.isChildSpaceOf(spaceId);
        if (isChildSpaceOf) {
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
      } catch (e, s) {
        _log.severe('Loading main Parent of $spaceId failed', e, s);
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
      } catch (e, s) {
        _log.severe('Loading other Parents of $spaceId failed', e, s);
      }
    }
  }
  return SpaceRelationsOverview(
    rel: relatedSpaces,
    membership: membership,
    parents: parents,
    knownChats: knownChats,
    knownSubspaces: knownSubspaces,
    otherRelations: otherRelated,
    mainParent: mainParent,
    hasMoreSubspaces: hasMoreSubspaces,
    hasMoreChats: hasMoreChats,
    suggestedIds: suggested,
  );
});

final hasSubChatsProvider =
    AsyncNotifierProvider.family<HasSubChatsNotifier, bool, String>(
  () => HasSubChatsNotifier(),
);

final hasSubSpacesProvider =
    AsyncNotifierProvider.family<HasSubSpacesNotifier, bool, String>(
  () => HasSubSpacesNotifier(),
);

final _spaceRemoteRelationsProvider =
    FutureProvider.family<List<SpaceHierarchyRoomInfo>, String>(
        (ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  if (relatedSpaces == null) {
    return [];
  }
  return (await relatedSpaces.queryHierarchy()).toList();
});

final remoteChatRelationsProvider =
    FutureProvider.family<List<SpaceHierarchyRoomInfo>, String>(
        (ref, spaceId) async {
  try {
    final relatedSpaces =
        await ref.watch(spaceRelationsOverviewProvider(spaceId).future);
    final toIgnore =
        relatedSpaces.knownChats.map((e) => e.getRoomIdStr()).toList();
    final roomHierarchy =
        await ref.watch(_spaceRemoteRelationsProvider(spaceId).future);
    // filter out the known rooms
    return roomHierarchy
        .where((r) => !r.isSpace() && !toIgnore.contains(r.roomIdStr()))
        .toList();
  } on SpaceNotFound {
    return [];
  }
});

final remoteSubspaceRelationsProvider =
    FutureProvider.family<List<SpaceHierarchyRoomInfo>, String>(
        (ref, spaceId) async {
  try {
    final relatedSpaces =
        await ref.watch(spaceRelationsOverviewProvider(spaceId).future);
    final toIgnore =
        relatedSpaces.knownSubspaces.map((e) => e.getRoomIdStr()).toList();
    toIgnore.addAll(relatedSpaces.parents.map((e) => e.getRoomIdStr()));
    if (relatedSpaces.mainParent != null) {
      toIgnore.add(relatedSpaces.mainParent!.getRoomIdStr());
    }
    toIgnore.add(spaceId); // the hierarchy also gives us ourselfes ...

    final roomHierarchy =
        await ref.watch(_spaceRemoteRelationsProvider(spaceId).future);
    // filter out the known rooms
    return roomHierarchy
        .where((r) => r.isSpace() && !toIgnore.contains(r.roomIdStr()))
        .toList();
  } on SpaceNotFound {
    return [];
  }
});

final acterAppSettingsProvider = FutureProvider.autoDispose
    .family<ActerAppSettings?, String>((ref, spaceId) async {
  final space = await ref.watch(maybeSpaceProvider(spaceId).future);
  if (space == null) {
    return null;
  }
  if (!await space.isActerSpace()) {
    return null;
  }
  return await space.appSettings();
});
