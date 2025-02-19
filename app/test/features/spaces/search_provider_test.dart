import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_space_providers.dart';

void main() {
  group('Spaces Search Provider Test', () {
    test(
        'Display Name update triggers proper update of search values on quick search',
        () async {
      final spaces = [
        MockSpace(id: 'a'),
        MockSpace(id: 'b'),
        MockSpace(id: 'c'),
      ];
      final Map<String, AvatarInfo> spaceInfos = {
        'a': const AvatarInfo(uniqueId: 'a', displayName: 'abc'),
        'b': const AvatarInfo(
          uniqueId: 'b',
          displayName: null,
        ), // not yet loaded
        'c': const AvatarInfo(uniqueId: 'c', displayName: null),
      };
      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWith(() => MockSpaceListNotifiers(spaces)),
          roomAvatarInfoProvider.overrideWith(
            () => MockRoomAvatarInfoNotifier(items: spaceInfos),
          ),
          bookmarkedSpacesProvider.overrideWith((a) => []),
        ],
      );

      final all = container.read(spaceListQuickSearchedProvider);
      expect(all.length, 3);

      // add a search term
      container.read(quickSearchValueProvider.notifier).state = 'a';

      final onlyOne = container.read(spaceListQuickSearchedProvider);
      expect(onlyOne.length, 1);

      // update a space info
      spaceInfos['b'] = const AvatarInfo(uniqueId: 'b', displayName: 'abc');
      // we only refresh the inner provider
      container.refresh(roomAvatarInfoProvider('b'));

      final itsTwo = container.read(spaceListQuickSearchedProvider);
      expect(itsTwo.length, 2);
    });

    test(
        'Display Name update triggers proper update of search values on list search',
        () async {
      final spaces = [
        MockSpace(id: 'a'),
        MockSpace(id: 'b'),
        MockSpace(id: 'c'),
      ];
      final Map<String, AvatarInfo> spaceInfos = {
        'a': const AvatarInfo(uniqueId: 'a', displayName: 'abc'),
        'b': const AvatarInfo(
          uniqueId: 'b',
          displayName: null,
        ), // not yet loaded
        'c': const AvatarInfo(uniqueId: 'c', displayName: null),
      };
      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWith(() => MockSpaceListNotifiers(spaces)),
          roomAvatarInfoProvider.overrideWith(
            () => MockRoomAvatarInfoNotifier(items: spaceInfos),
          ),
          bookmarkedSpacesProvider.overrideWith((a) => []),
        ],
      );

      final all = container.read(spaceListSearchProvider);
      expect(all.length, 3);

      // add a search term
      container.read(spaceListSearchTermProvider.notifier).state = 'a';

      final onlyOne = container.read(spaceListSearchProvider);
      expect(onlyOne.length, 1);

      // update a space info
      spaceInfos['b'] = const AvatarInfo(uniqueId: 'b', displayName: 'abc');
      // we only refresh the inner provider
      container.refresh(roomAvatarInfoProvider('b'));

      final itsTwo = container.read(spaceListSearchProvider);
      expect(itsTwo.length, 2);
    });
  });
}
