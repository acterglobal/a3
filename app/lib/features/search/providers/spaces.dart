import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/search/model/base_delegate.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/search/providers/search.dart';

class SpaceDetails extends BaseDelegate {
  final ActerAvatar icon;
  const SpaceDetails(String navigationTarget, String name, {required this.icon})
      : super(name: name, navigationTarget: navigationTarget);
}

final AutoDisposeFutureProvider<List<SpaceDetails>> spacesFoundProvider =
    FutureProvider.autoDispose((ref) async {
  final spaces = ref.watch(spacesProvider);
  final List<SpaceDetails> finalSpaces = [];
  final searchValue = ref.watch(searchValueProvider).toLowerCase();

  for (final space in spaces) {
    final info = await ref.watch(spaceProfileDataProvider(space).future);
    final roomId = space.getRoomId().toString();
    if (searchValue.isNotEmpty) {
      if (!(info.displayName!.toLowerCase()).contains(searchValue)) {
        continue;
      }
    }
    finalSpaces.add(
      SpaceDetails(
        icon: ActerAvatar(
          mode: DisplayMode.Space,
          avatarInfo: AvatarInfo(
            uniqueId: roomId,
            displayName: info.displayName,
            avatar: info.getAvatarImage(),
          ),
        ),
        '/$roomId',
        info.displayName ?? roomId,
      ),
    );
  }

  finalSpaces.sort((a, b) {
    return a.name.compareTo(b.name);
  });
  return finalSpaces;
});
