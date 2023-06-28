import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/search/providers/search.dart';

Iterable<T> filterMap<T, E>(Iterable<E> oi, T? Function(E? e) toElement) sync* {
  for (var value in oi) {
    final T? smth = toElement(value);
    if (smth != null) {
      yield smth;
    }
  }
}

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
  final searchValue = ref.watch(searchValueProvider);

  spaces.sort((a, b) {
    // FIXME probably not the way we want to sort
    /// but at least this gives us a predictable order
    return a.getRoomId().toString().compareTo(b.getRoomId().toString());
  });

  return filterMap(spaces, (space) {
    if (space == null) {
      return null;
    }
    final profileData = ref.watch(spaceProfileDataProvider(space));
    final roomId = space.getRoomId().toString();
    return profileData.when(
      loading: () => null,
      error: (err, _trace) => null,
      data: (info) {
        if (searchValue.isNotEmpty) {
          if (!(info.displayName ?? '').contains(searchValue)) {
            return null;
          }
        }
        return SpaceDetails._(
          ActerAvatar(
            uniqueId: roomId,
            displayName: info.displayName,
            mode: DisplayMode.Space,
            avatar: info.getAvatarImage(),
          ),
          info.displayName ?? roomId,
          '/$roomId',
        );
      },
    );
  }).toList();
});
