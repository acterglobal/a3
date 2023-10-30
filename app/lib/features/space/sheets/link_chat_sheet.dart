import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkChatPage extends ConsumerStatefulWidget {
  final String? parentSpaceId;

  const LinkChatPage({super.key, required this.parentSpaceId});

  @override
  ConsumerState<LinkChatPage> createState() => _LinkChatPageConsumerState();
}

class _LinkChatPageConsumerState extends ConsumerState<LinkChatPage> {
  final TextEditingController searchTextEditingController =
      TextEditingController();
  final List<String> subChatsIds = [];

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

  //Fetch known sub-chats list of selected parent space
  void fetchKnownSubChatsData() {
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;
    final sp = ref.watch(spaceRelationsOverviewProvider(selectedParentSpaceId));
    sp.when(
      data: (space) {
        subChatsIds.clear();
        for (int i = 0; i < space.knownChats.length; i++) {
          subChatsIds.add(space.knownChats[i].getRoomId().toString());
        }
      },
      error: (e, s) => Container(),
      loading: () => Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    //Fetch known sub-chats list of selected parent space
    fetchKnownSubChatsData();

    return SideSheet(
      header: 'Link Sub-Chat',
      body: SizedBox(
        height: size.height - 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            parentSpaceSelector(context, ref),
            Search(
              onChanged: (value) => ref
                  .read(chatSearchValueProvider.notifier)
                  .update((state) => value),
              searchController: searchTextEditingController,
            ),
            Expanded(child: chatsList(context, ref)),
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
        emptyText: 'optional parent space',
        selectTitle: 'Select parent space',
      ),
    );
  }

  //List of chats excluding DMs that can be linked according to the selected parent space
  Widget chatsList(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(chatSearchValueProvider);
    if (searchValue != null && searchValue.isNotEmpty) {
      return ref.watch(searchedChatsProvider).when(
            data: (chats) {
              var chatList =
                  chats.where((element) => (!element.isDm())).toList();
              if (chatList.isEmpty) {
                return const Center(
                  heightFactor: 10,
                  child: Text('No chats found matching your search term'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: chatList.length,
                itemBuilder: (context, index) {
                  return chatsListItemUI(chatList[index].getRoomIdStr());
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

    final chats =
        ref.watch(chatsProvider).where((element) => (!element.isDm())).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        return chatsListItemUI(chats[index].getRoomIdStr());
      },
    );
  }

  //Chats list item UI
  Widget chatsListItemUI(String roomId) {
    final roomItem = ref.watch(briefRoomItemWithMembershipProvider(roomId));

    return roomItem.when(
      data: (roomProfile) {
        final membership = roomProfile.membership;
        final canLink =
            membership == null ? false : membership.canString('CanLinkSpaces');
        final isLinked = subChatsIds.contains(roomId);

        return widget.parentSpaceId == roomId
            ? Container()
            : ListTile(
                enabled: canLink,
                leading: ActerAvatar(
                  mode: DisplayMode.Space,
                  displayName: roomProfile.roomProfileData.displayName,
                  uniqueId: roomId,
                  avatar: roomProfile.roomProfileData.getAvatarImage(),
                  size: 24,
                ),
                title: Text(roomProfile.roomProfileData.displayName ?? roomId),
                trailing: SizedBox(
                  width: 100,
                  child: isLinked
                      ? DefaultButton(
                          onPressed: () => onTapUnlinkSubChat(),
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
                              onPressed: () => onTapLinkSubChat(roomId),
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
      },
      skipLoadingOnReload: false,
      error: (err, stackTrace) => Container(),
      loading: () => Container(),
    );
  }

  void onTapLinkSubChat(String roomId) {
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;
    final space = ref.watch(spaceProvider(selectedParentSpaceId));
    space.when(
      data: (space) {
        space.addChildSpace(roomId);
      },
      error: (e, s) => Container(),
      loading: () => Container(),
    );
  }

  void onTapUnlinkSubChat() {}
}
