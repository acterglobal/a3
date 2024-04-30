import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/space_notifiers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::space_providers');

/// Provider the profile data of a the given space, keeps up to date with underlying client
final spaceProfileDataProvider = AsyncNotifierProvider.family<
    AsyncSpaceProfileDataNotifier, ProfileData, Space>(
  () => AsyncSpaceProfileDataNotifier(),
);

/// Provider the list of all spaces, keeps up to date with the order and the underlying client
final spacesProvider =
    StateNotifierProvider<SpaceListNotifier, List<Space>>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return SpaceListNotifier(ref: ref, client: client);
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

/// Load the SpaceProfile Data right from the spaceId
final spaceProfileDataForSpaceIdProvider = FutureProvider.autoDispose
    .family<SpaceWithProfileData, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  final SpaceWithProfileData data = (space: space, profile: profileData);
  return data;
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
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  final membership = await space.getMyMembership();
  return SpaceItem(
    space: space,
    roomId: space.getRoomIdStr(),
    membership: membership,
    activeMembers: [],
    spaceProfileData: profileData,
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
    items.add(
      (
        space.getRoomIdStr(),
        (await space.getProfile().getDisplayName()).text()
      ),
    );
  }
  return items;
});

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
  final profileData = await ref.watch(spaceProfileDataProvider(space).future);
  return SpaceItem(
    roomId: space.getRoomIdStr(),
    membership: null,
    activeMembers: [],
    spaceProfileData: profileData,
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
final spaceRelationsOverviewProvider = FutureProvider.autoDispose
    .family<SpaceRelationsOverview, String>((ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  if (relatedSpaces == null) {
    throw 'Space not found';
  }
  final membership = await ref.watch(roomMembershipProvider(spaceId).future);
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
  final avatar = await space.getAvatar(null);
  return ProfileData(space.name(), avatar.data());
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
