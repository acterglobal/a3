import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/search/providers/search.dart';

const fallbackSidebarIdx = 1;
const fallbackBottomBarIdx = 0;

class SpaceDetails {
  final String navigationTarget;
  final ActerAvatar icon;
  final String name;

  const SpaceDetails._(this.icon, this.name, this.navigationTarget);
}

final AutoDisposeFutureProvider<List<SpaceDetails>> spacesFoundProvider =
    FutureProvider.autoDispose((ref) async {
  final spaces = await ref.watch(spacesProvider.future);
  final List<SpaceDetails> finalSpaces = [];
  final searchValue = ref.watch(searchValueProvider);

  for (final space in spaces) {
    final info = await ref.watch(spaceProfileDataProvider(space).future);
    final roomId = space.getRoomId().toString();
    if (searchValue.isNotEmpty) {
      if (!(info.displayName ?? '').contains(searchValue)) {
        continue;
      }
    }
    finalSpaces.add(
      SpaceDetails._(
        ActerAvatar(
          uniqueId: roomId,
          displayName: info.displayName,
          mode: DisplayMode.Space,
          avatar: info.getAvatarImage(),
        ),
        info.displayName ?? roomId,
        '/$roomId',
      ),
    );
  }

  finalSpaces.sort((a, b) {
    return a.name.compareTo(b.name);
  });
  return finalSpaces;
});
