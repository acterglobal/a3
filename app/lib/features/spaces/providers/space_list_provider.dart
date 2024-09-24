import 'package:acter/common/providers/space_providers.dart';
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
