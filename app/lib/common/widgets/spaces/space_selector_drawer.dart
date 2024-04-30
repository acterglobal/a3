import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

const Key selectSpaceDrawerKey = Key('space-widgets-select-space-drawer');

class _SelectSpaceDrawer extends ConsumerStatefulWidget {
  final String canCheck;
  final String? currentSpaceId;
  final Widget? title;
  const _SelectSpaceDrawer({
    super.key,
    this.canCheck = 'CanLinkSpaces',
    this.currentSpaceId,
    this.title,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __SelectSpaceDrawerState();
}

class __SelectSpaceDrawerState extends ConsumerState<_SelectSpaceDrawer> {
  final TextEditingController searchTextController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ensure we are synced up
    searchTextController.text = ref.read(spaceSearchValueProvider) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        key: widget.key,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          title(context),
          searchBar(context),
          Flexible(
            child: spacesList(context),
          ),
        ],
      ),
    );
  }

  Widget title(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: widget.title ?? Text(L10n.of(context).selectSpace),
      actions: [
        TextButton.icon(
          icon: const Icon(Atlas.minus_circle_thin),
          onPressed: () {
            Navigator.pop(context, '');
          },
          label: Text(L10n.of(context).clear),
        ),
      ],
    );
  }

  Widget searchBar(BuildContext context) {
    final spaces = ref.watch(spacesProvider);
    if (spaces.length < 10) {
      // small list, ignore
      return const SizedBox.shrink();
    }

    final hasSearchTerm = (ref.read(spaceSearchValueProvider) ?? '').isNotEmpty;

    return SearchBar(
      controller: searchTextController,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Atlas.magnifying_glass),
      ),
      hintText: L10n.of(context).search,
      trailing: hasSearchTerm
          ? [
              InkWell(
                onTap: () {
                  searchTextController.clear();
                  ref.read(spaceSearchValueProvider.notifier).state = '';
                },
                child: const Icon(Icons.clear),
              ),
            ]
          : null,
      onChanged: (value) {
        ref.read(spaceSearchValueProvider.notifier).state = value;
      },
    );
  }

  Widget spacesList(BuildContext context) {
    final searchValue = ref.watch(spaceSearchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      return searchedSpaceList(context);
    }

    final spaces =
        ref.watch(spacesProvider).map((space) => space.getRoomIdStr()).toList();
    return spaceListUI(spaces);
  }

//Show space list based on the search term
  Widget searchedSpaceList(BuildContext context) {
    final searchedSpaces = ref.watch(searchedSpacesProvider);
    return searchedSpaces.when(
      data: (spaces) {
        if (spaces.isEmpty) {
          return Center(
            heightFactor: 10,
            child: Text(L10n.of(context).noChatsFoundMatchingYourSearchTerm),
          );
        }
        return spaceListUI(spaces);
      },
      loading: () => const Center(
        heightFactor: 10,
        child: CircularProgressIndicator(),
      ),
      error: (e, s) => Center(child: Text(L10n.of(context).searchingFailed(e))),
    );
  }

  Widget spaceListUI(List<String> spaces) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: spaces.length,
      itemBuilder: (context, index) {
        final roomId = spaces[index];
        return BriefRoomEntry(
          roomId: roomId,
          avatarDisplayMode: DisplayMode.Space,
          keyPrefix: 'select-space',
          selectedValue: current,
          canCheck: widget.canCheck,
          onSelect: (roomId) {
            Navigator.pop(context, roomId);
          },
        );
      },
    );
  }
}

Future<String?> selectSpaceDrawer({
  required BuildContext context,
  Key? key = selectSpaceDrawerKey,
  String canCheck = 'CanLinkSpaces',
  String? currentSpaceId,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    builder: (context) => _SelectSpaceDrawer(
      key: key,
      canCheck: canCheck,
      currentSpaceId: currentSpaceId,
      title: title,
    ),
  );
  if (selected == null) {
    // in case of being dismissed, we return the previously selected item
    return currentSpaceId;
  }
  if (selected == '') {
    // in case of being cleared, we return null
    return null;
  }
  return selected;
}
