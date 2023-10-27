import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
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
  final List<String> subSpacesIds = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      selectParentSpaceData();
    });
    super.initState();
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
    sp.when(
      data: (space) {
        subSpacesIds.clear();
        for (int i = 0; i < space.knownSubspaces.length; i++) {
          subSpacesIds.add(space.knownSubspaces[i].getRoomId().toString());
        }
      },
      error: (e, s) => Container(),
      loading: () => Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Fetch known sub-spaces list of selected parent space
    fetchKnownSubspacesData();

    return SideSheet(
      header: 'Link Sub-Space',
      body: Column(
        children: [
          parentSpaceSelector(context, ref),
          spacesList(context, ref),
        ],
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
        emptyText: 'optional parent space',
        selectTitle: 'Select parent space',
      ),
    );
  }

  //List of spaces that can be linked according to the selected parent space
  Widget spacesList(BuildContext context, WidgetRef ref) {
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
    final membership = item.membership!;
    final profile = item.spaceProfileData;
    final roomId = item.roomId;
    final canLink = membership.canString('CanLinkSpaces');
    final isLinked = subSpacesIds.contains(item.roomId);
    return widget.parentSpaceId == roomId
        ? Container()
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
                      onPressed: () => onTapUnlinkSubSpace(),
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
                          onPressed: () => onTapLinkSubSpace(),
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

  void onTapLinkSubSpace() {}

  void onTapUnlinkSubSpace() {}
}
