import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkSpacePage extends ConsumerStatefulWidget {
  final String? parentSpaceId;

  const LinkSpacePage({super.key, required this.parentSpaceId});

  @override
  ConsumerState<LinkSpacePage> createState() => _LinkSpacePageConsumerState();
}

class _LinkSpacePageConsumerState extends ConsumerState<LinkSpacePage> {
  final TextEditingController searchTextEditingController =
      TextEditingController();
  final List<String> subSpacesIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      selectParentSpaceData();
    });
  }

  //Select parent space data
  void selectParentSpaceData() {
    if (widget.parentSpaceId != null) {
      final notifier = ref.read(selectedSpaceIdProvider.notifier);
      notifier.state = widget.parentSpaceId;
    }
  }

  //Fetch known sub-spaces list of selected parent space
  void fetchKnownSubspacesData() {
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;
    final sp = ref.watch(spaceRelationsOverviewProvider(selectedParentSpaceId));
    sp.whenData(
      (space) {
        subSpacesIds.clear();
        for (int i = 0; i < space.knownSubspaces.length; i++) {
          subSpacesIds.add(space.knownSubspaces[i].getRoomId().toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    //Fetch known sub-spaces list of selected parent space
    fetchKnownSubspacesData();

    return SideSheet(
      header: 'Link Sub-Space',
      body: SizedBox(
        height: size.height - 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            parentSpaceSelector(context, ref),
            Search(
              onChanged: (value) => ref
                  .read(spaceSearchValueProvider.notifier)
                  .update((state) => value),
              searchController: searchTextEditingController,
            ),
            Expanded(child: spacesList(context, ref)),
          ],
        ),
      ),
    );
  }

  //Parent space selector
  Widget parentSpaceSelector(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: SelectSpaceFormField(
        canCheck: 'CanLinkSpaces',
        mandatory: true,
        title: 'Parent space',
        emptyText: '(none selected)',
        selectTitle: 'Select parent space',
      ),
    );
  }

  //List of spaces that can be linked according to the selected parent space
  Widget spacesList(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(spaceSearchValueProvider);
    if (searchValue != null && searchValue.isNotEmpty) {
      return ref.watch(searchedSpacesProvider).when(
            data: (spaces) {
              if (spaces.isEmpty) {
                return const Center(
                  heightFactor: 10,
                  child: Text('No chats found matching your search term'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: spaces.length,
                itemBuilder: (context, index) {
                  return spaceListItemUI(spaces[index]);
                },
              );
            },
            loading: () => const Center(
              heightFactor: 10,
              child: CircularProgressIndicator(),
            ),
            error: (e, s) => Center(
              heightFactor: 10,
              child: Text(
                'Searching failed: $e',
              ),
            ),
          );
    }

    final spacesList = ref.watch(briefSpaceItemsProviderWithMembership);
    return spacesList.when(
      data: (spaces) => spaces.isEmpty
          ? const Text('no spaces found')
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                return spaceListItemUI(spaces[index]);
              },
            ),
      error: (e, s) => Center(
        child: Text('error loading spaces: $e'),
      ),
      loading: () => const Center(
        child: Text('loading'),
      ),
    );
  }

  //Space list item UI
  Widget spaceListItemUI(SpaceItem item) {
    final membership = item.membership;
    final profile = item.spaceProfileData;
    final roomId = item.roomId;
    final canLink =
        membership == null ? false : membership.canString('CanLinkSpaces');
    final isLinked = subSpacesIds.contains(item.roomId);
    return widget.parentSpaceId == roomId
        ? const SizedBox.shrink()
        : ListTile(
            enabled: canLink,
            leading: ActerAvatar(
              mode: DisplayMode.Space,
              displayName: profile.displayName,
              uniqueId: roomId,
              avatar: profile.getAvatarImage(),
              size: 24,
            ),
            title: Text(profile.displayName ?? roomId),
            trailing: SizedBox(
              width: 100,
              child: isLinked
                  ? DefaultButton(
                      onPressed: () => onTapUnlinkSubSpace(roomId),
                      title: 'Unlink',
                      isOutlined: true,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                  : canLink
                      ? DefaultButton(
                          onPressed: () => onTapLinkSubSpace(roomId),
                          title: 'Link',
                          isOutlined: true,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.success,
                            ),
                          ),
                        )
                      : null,
            ),
          );
  }

  void onTapLinkSubSpace(String roomId) async {
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.watch(spaceProvider(selectedParentSpaceId).future);
    space.addChildRoom(roomId);

    //Fetch selected room data and add given parentSpaceId as parent
    final room = await ref.watch(maybeRoomProvider(roomId).future);
    if (room != null) {
      room.addParentRoom(selectedParentSpaceId, true);
    }
  }

  void onTapUnlinkSubSpace(String roomId) async {
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.watch(spaceProvider(selectedParentSpaceId).future);
    space.removeChildRoom(roomId, 'Unlink room');
  }
}
