import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/search/model/search_term_delegate.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter_avatar/acter_avatar.dart';
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

final AutoDisposeFutureProvider<List<SpaceDetails>> spacesFoundProvider =
    FutureProvider.autoDispose((ref) async {
  final spaces = ref.watch(spacesProvider);
  final List<SpaceDetails> finalSpaces = [];
  final searchValue = ref.watch(searchValueProvider).toLowerCase();

  for (final space in spaces) {
    final info = await ref.watch(spaceProfileDataProvider(space).future);
    final roomId = space.getRoomIdStr();
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
          mode: DisplayMode.Space,
          avatarInfo: AvatarInfo(
            uniqueId: roomId,
            displayName: info.displayName,
            avatar: info.getAvatarImage(),
          ),
        ),
      ),
    );
  }

  finalSpaces.sort((a, b) {
    return a.name.compareTo(b.name);
  });
  return finalSpaces;
});
