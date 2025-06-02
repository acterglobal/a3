import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/room/providers/user_settings_provider.dart';
import 'package:acter/features/space/providers/notifiers/relations_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::space::suggested_provider');

// Whether or not to prompt the user about the suggested rooms.
final shouldShowSuggestedProvider = FutureProvider.family<bool, String>((
  ref,
  spaceId,
) async {
  try {
    final settings = await ref.read(roomUserSettingsProvider(spaceId).future);
    if (settings.hasSeenSuggested()) {
      return false;
    }

    final suggestedRooms = await ref.watch(
      roomsToSuggestProvider(spaceId).future,
    );
    // only if we really have some remote rooms that the user is suggested and not yet in
    return suggestedRooms.chats.isNotEmpty || suggestedRooms.spaces.isNotEmpty;
  } catch (e, s) {
    _log.severe('Fetching suggestions showing failed', e, s);
    return false;
  }
});

typedef SuggestedRooms =
    ({List<SpaceHierarchyRoomInfo> spaces, List<SpaceHierarchyRoomInfo> chats});

// Will show the room _to_ suggest to the user, ergo excludes rooms they are
// already in
final roomsToSuggestProvider = FutureProvider.family<SuggestedRooms, String>((
  ref,
  roomId,
) async {
  final chats = await ref.watch(remoteChatRelationsProvider(roomId).future);
  final spaces = await ref.watch(
    remoteSubspaceRelationsProvider(roomId).future,
  );

  return (
    chats: chats.where((r) => r.suggested()).toList(),
    spaces: spaces.where((r) => r.suggested()).toList(),
  );
});

final suggestedIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  spaceId,
) async {
  return (await ref.watch(
    spaceRelationsOverviewProvider(spaceId).future,
  )).suggestedIds;
});

final hasSubChatsProvider =
    AsyncNotifierProvider.family<HasSubChatsNotifier, bool, String>(
      () => HasSubChatsNotifier(),
    );

final hasSubSpacesProvider =
    AsyncNotifierProvider.family<HasSubSpacesNotifier, bool, String>(
      () => HasSubSpacesNotifier(),
    );

final spaceRemoteRelationsProvider = FutureProvider.family<
  List<SpaceHierarchyRoomInfo>,
  String
>((ref, spaceId) async {
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  if (relatedSpaces == null) return [];
  return (await relatedSpaces.queryHierarchy()).toList();
});

final remoteChatRelationsProvider =
    FutureProvider.family<List<SpaceHierarchyRoomInfo>, String>((
      ref,
      spaceId,
    ) async {
      try {
        final relatedSpaces = await ref.watch(
          spaceRelationsOverviewProvider(spaceId).future,
        );
        final toIgnore = relatedSpaces.knownChats.toList();
        final roomHierarchy = await ref.watch(
          spaceRemoteRelationsProvider(spaceId).future,
        );
        // filter out the known rooms
        return roomHierarchy
            .where((r) => !r.isSpace() && !toIgnore.contains(r.roomIdStr()))
            .toList();
      } on SpaceNotFound {
        return [];
      }
    });

typedef RoomsAndRoomInfos = (List<String>, List<SpaceHierarchyRoomInfo>);

final suggestedChatsProvider = FutureProvider.family<RoomsAndRoomInfos, String>(
  (ref, spaceId) async {
    try {
      //Fetch suggested chat ids
      final suggestedId = await ref.watch(suggestedIdsProvider(spaceId).future);

      //Return empty lists if there no suggested chats
      if (suggestedId.isEmpty) {
        return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
      }

      //Fetch Local and Remote Chats
      final relatedSpaces = await ref.watch(
        spaceRelationsOverviewProvider(spaceId).future,
      );
      final relatedChats = await ref.watch(
        remoteChatRelationsProvider(spaceId).future,
      );

      //Filter suggested local and remote chats
      final localSuggestedChats =
          relatedSpaces.knownChats
              .where((roomId) => suggestedId.contains(roomId))
              .toList();
      final remoteSuggestedChats =
          relatedChats
              .where((room) => suggestedId.contains(room.roomIdStr()))
              .toList();
      return (localSuggestedChats, remoteSuggestedChats);
    } on SpaceNotFound {
      return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
    }
  },
);

final otherChatsProvider = FutureProvider.family<RoomsAndRoomInfos, String>((
  ref,
  spaceId,
) async {
  try {
    //Fetch suggested chat ids
    final suggestedId = await ref.watch(suggestedIdsProvider(spaceId).future);

    //Fetch Local and Remote Chats
    final relatedSpaces = await ref.watch(
      spaceRelationsOverviewProvider(spaceId).future,
    );
    final relatedChats = await ref.watch(
      remoteChatRelationsProvider(spaceId).future,
    );

    //Return local and remote chats directly if suggested ids is empty
    if (suggestedId.isEmpty) {
      return (relatedSpaces.knownChats, relatedChats);
    }

    //Exclude suggested chats
    final localOtherChats =
        relatedSpaces.knownChats
            .where((roomId) => !suggestedId.contains(roomId))
            .toList();
    final remoteOtherChats =
        relatedChats
            .where((room) => !suggestedId.contains(room.roomIdStr()))
            .toList();

    return (localOtherChats, remoteOtherChats);
  } on SpaceNotFound {
    return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
  }
});

final suggestedSpacesProvider =
    FutureProvider.family<RoomsAndRoomInfos, String>((ref, spaceId) async {
      try {
        //Fetch suggested ids
        final suggestedId = await ref.watch(
          suggestedIdsProvider(spaceId).future,
        );

        //Return empty lists if there no suggested sub-spaces
        if (suggestedId.isEmpty) {
          return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
        }

        //Fetch Local and Remote sub-spaces
        final relatedSpaces = await ref.watch(
          spaceRelationsOverviewProvider(spaceId).future,
        );
        final remoteSubSpaces = await ref.watch(
          remoteSubspaceRelationsProvider(spaceId).future,
        );

        //Filter suggested local and remote sub-spaces
        final localSuggestedSpaces =
            relatedSpaces.knownSubspaces
                .where((roomId) => suggestedId.contains(roomId))
                .toList();
        final remoteSuggestedSpaces =
            remoteSubSpaces
                .where((room) => suggestedId.contains(room.roomIdStr()))
                .toList();
        return (localSuggestedSpaces, remoteSuggestedSpaces);
      } on SpaceNotFound {
        return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
      }
    });

final otherSubSpacesProvider = FutureProvider.family<RoomsAndRoomInfos, String>(
  (ref, spaceId) async {
    try {
      //Fetch suggested ids
      final suggestedId = await ref.watch(suggestedIdsProvider(spaceId).future);

      //Fetch Local and Remote sub-spaces
      final relatedSpaces = await ref.watch(
        spaceRelationsOverviewProvider(spaceId).future,
      );
      final remoteSubSpaces = await ref.watch(
        remoteSubspaceRelationsProvider(spaceId).future,
      );

      //Return local and remote sub-spaces directly if suggested ids is empty
      if (suggestedId.isEmpty) {
        return (relatedSpaces.knownSubspaces, remoteSubSpaces);
      }

      //Exclude suggested sub-spaces
      final localOtherChats =
          relatedSpaces.knownSubspaces
              .where((roomId) => !suggestedId.contains(roomId))
              .toList();
      final remoteOtherChats =
          remoteSubSpaces
              .where((room) => !suggestedId.contains(room.roomIdStr()))
              .toList();

      return (localOtherChats, remoteOtherChats);
    } on SpaceNotFound {
      return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
    }
  },
);

final remoteSubspaceRelationsProvider =
    FutureProvider.family<List<SpaceHierarchyRoomInfo>, String>((
      ref,
      spaceId,
    ) async {
      try {
        final relatedSpaces = await ref.watch(
          spaceRelationsOverviewProvider(spaceId).future,
        );
        final toIgnore = List.of(relatedSpaces.knownSubspaces);
        toIgnore.addAll(relatedSpaces.parents.map((e) => e.getRoomIdStr()));
        relatedSpaces.mainParent.map((p) => toIgnore.add(p.getRoomIdStr()));
        toIgnore.add(spaceId); // the hierarchy also gives us ourselfes ...

        final roomHierarchy = await ref.watch(
          spaceRemoteRelationsProvider(spaceId).future,
        );
        // filter out the known rooms
        return roomHierarchy
            .where((r) => r.isSpace() && !toIgnore.contains(r.roomIdStr()))
            .toList();
      } on SpaceNotFound {
        return [];
      }
    });
