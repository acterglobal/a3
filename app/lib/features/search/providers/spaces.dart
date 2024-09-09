import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/search/model/search_term_delegate.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

const fallbackSidebarIdx = 1;
const fallbackBottomBarIdx = 0;

class SpaceDetails extends SearchTermDelegate {
  final ActerAvatar icon;

  const SpaceDetails(
    String name,
    String navigationTargetId, {
    required this.icon,
  }) : super(name: name, navigationTargetId: navigationTargetId);
}

List<SpaceDetails> _filterSpaces(
    Ref ref, String searchValue, List<Space> spaces) {
  final List<SpaceDetails> finalSpaces = [];

  for (final space in spaces) {
    final roomId = space.getRoomIdStr();
    final info = ref.watch(roomAvatarInfoProvider(roomId));

    if (searchValue.isNotEmpty) {
      if (!(info.displayName!.toLowerCase()).contains(searchValue)) {
        continue;
      }
    }
    finalSpaces.add(
      SpaceDetails(
        info.displayName ?? roomId,
        roomId,
        icon: ActerAvatar(
          options: AvatarOptions(
            info,
          ),
        ),
      ),
    );
  }

  finalSpaces.sort((a, b) {
    return a.name.compareTo(b.name);
  });
  return finalSpaces;
}

final AutoDisposeFutureProvider<List<SpaceDetails>> spacesFoundProvider =
    FutureProvider.autoDispose((ref) async {
  final searchValue = ref.watch(searchValueProvider).toLowerCase();
  // filter and sort them separately to keep the bookmarks at the beginning.
  final allSpaces =
      _filterSpaces(ref, searchValue, ref.watch(bookmarkedSpacesProvider));
  allSpaces.addAll(
    _filterSpaces(ref, searchValue, ref.watch(unbookmarkedSpacesProvider)),
  );
  return allSpaces;
});
