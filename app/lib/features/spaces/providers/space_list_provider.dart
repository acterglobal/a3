import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Search Value provider for space list
final spaceListSearchTermProvider = StateProvider<String>((ref) => '');

final subSpacesListProvider =
    FutureProvider.family<List<String>, String>((ref, spaceId) async {
  List<String> subSpacesList = [];

  //Get known sub-spaces
  final spaceRelationsOverview =
      await ref.watch(spaceRelationsOverviewProvider(spaceId).future);
  subSpacesList.addAll(spaceRelationsOverview.knownSubspaces);

  //Get more sub-spaces
  final relatedSpacesLoader =
      await ref.watch(remoteSubspaceRelationsProvider(spaceId).future);
  for (var element in relatedSpacesLoader) {
    subSpacesList.add(element.roomIdStr());
  }

  return subSpacesList;
});

final allSpaceListWithBookmarkFirstProvider =
    Provider.autoDispose<List<Space>>((ref) {
  final bookmarkedSpaceList = ref.watch(bookmarkedSpacesProvider);
  final othersSpaceList = ref.watch(unbookmarkedSpacesProvider);
  final spaceList = bookmarkedSpaceList.followedBy(othersSpaceList);
  return spaceList.toList();
});

List<Space> _filterByTerm(Ref ref, List<Space> spaceList, String searchValue) =>
    spaceList.where((space) {
      final roomId = space.getRoomIdStr();
      final spaceInfo = ref.watch(roomAvatarInfoProvider(roomId));
      final spaceName = spaceInfo.displayName ?? roomId;
      return spaceName.toLowerCase().contains(searchValue);
    }).toList();

final spaceListSearchProvider = Provider.autoDispose<List<Space>>((ref) {
  final spaceList = ref.watch(allSpaceListWithBookmarkFirstProvider);
  final searchTerm =
      ref.watch(spaceListSearchTermProvider).trim().toLowerCase();

  //Return all spaces if search is empty
  final searchValue = searchTerm.trim().toLowerCase();
  if (searchValue.isEmpty) return spaceList;
  return _filterByTerm(ref, spaceList, searchValue);
});

//Space list for quick search value provider
final spaceListQuickSearchedProvider = Provider.autoDispose<List<Space>>((ref) {
  final spaceList = ref.watch(allSpaceListWithBookmarkFirstProvider);
  final searchTerm = ref.watch(quickSearchValueProvider).trim().toLowerCase();

  //Return all spaces if search is empty
  final searchValue = searchTerm.trim().toLowerCase();
  if (searchValue.isEmpty) return spaceList;
  return _filterByTerm(ref, spaceList, searchValue);
});
