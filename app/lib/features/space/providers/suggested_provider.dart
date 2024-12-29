import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::space::suggested_provider');

// Whether or not to prompt the user about the suggested rooms.
final shouldShowSuggestedProvider =
    FutureProvider.family<bool, String>((ref, spaceId) async {
  final room = ref.watch(maybeRoomProvider(spaceId));
  if (room == null) {
    return false;
  }
  try {
    if (await room.userHasSeenSuggested()) {
      return false;
    }

    final suggestedRooms =
        await ref.watch(roomsToSuggestProvider(spaceId).future);
    // only if we really have some remote rooms that the user is suggested and not yet in
    return suggestedRooms.chats.isNotEmpty || suggestedRooms.spaces.isNotEmpty;
  } catch (e, s) {
    _log.severe('Fetching suggestions showing failed', e, s);
    return false;
  }
});

typedef SuggestedRooms = ({
  List<SpaceHierarchyRoomInfo> spaces,
  List<SpaceHierarchyRoomInfo> chats
});

// Will show the room _to_ suggest to the user, ergo excludes rooms they are
// already in
final roomsToSuggestProvider =
    FutureProvider.family<SuggestedRooms, String>((ref, roomId) async {
  final chats = await ref.watch(remoteChatRelationsProvider(roomId).future);
  final spaces =
      await ref.watch(remoteSubspaceRelationsProvider(roomId).future);

  return (
    chats: chats.where((r) => r.suggested()).toList(),
    spaces: spaces.where((r) => r.suggested()).toList()
  );
});
