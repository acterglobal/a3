import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final spaceListSearchProvider = FutureProvider.autoDispose
    .family<List<Space>, String>((ref, searchText) async {
  final bookmarkedSpaceList = ref.watch(bookmarkedSpacesProvider);
  final othersSpaceList = ref.watch(unbookmarkedSpacesProvider);
  final spaceList = bookmarkedSpaceList.followedBy(othersSpaceList);

  //Return all spaces if search is empty
  final searchValue = searchText.trim().toLowerCase();
  if (searchValue.isEmpty) return spaceList.toList();

  //Return all spaces with search criteria
  return spaceList.where((space) {
    final roomId = space.getRoomIdStr();
    final spaceInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final spaceName = spaceInfo.displayName ?? roomId;
    return spaceName.toLowerCase().contains(searchValue);
  }).toList();
});
