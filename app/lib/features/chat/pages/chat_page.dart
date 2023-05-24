import 'dart:ui';

import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/widgets/invite_info_card.dart';
import 'package:acter/features/chat/widgets/list_item.dart';
import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/models/JoinedRoom.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, Invitation, RoomId;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: GetBuilder<ChatListController>(
        id: 'chatlist',
        builder: (controller) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                pinned: false,
                snap: false,
                floating: true,
                flexibleSpace: controller.showSearch
                    ? Padding(
                        padding: const EdgeInsets.only(
                          top: 5,
                          bottom: 6,
                          left: 10,
                          right: 5,
                        ),
                        child: TextField(
                          onChanged: (value) {
                            controller.searchedData(
                              value,
                              controller.joinedRooms,
                            );
                          },
                          cursorColor: Theme.of(context).colorScheme.tertiary2,
                          controller: controller.searchController,
                          decoration: InputDecoration(
                            hintStyle: const TextStyle(
                              color: Colors.white,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                controller.toggleSearchView();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 12,
                              bottom: 2,
                              top: 2,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          AppLocalizations.of(context)!.chat,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                actions: controller.showSearch
                    ? []
                    : [
                        IconButton(
                          onPressed: () => controller.toggleSearchView(),
                          padding: const EdgeInsets.only(right: 10, left: 5),
                          icon: const Icon(
                            Atlas.magnifying_glass,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showNotYetImplementedMsg(
                              context,
                              'Multiselect is not implemented yet',
                            );
                          },
                          padding: const EdgeInsets.only(right: 10, left: 5),
                          icon: const Icon(
                            Atlas.menu_square,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showNotYetImplementedMsg(
                              context,
                              'Starting a new chat is not implemented yet',
                            );
                          },
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          icon: const Icon(
                            Atlas.plus_circle_thin,
                          ),
                        ),
                      ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (client.isGuest())
                      empty
                    else
                      _ListWidget(client: client),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SvgPicture get empty {
    return SvgPicture.asset('assets/images/empty_messages.svg');
  }
}

class _ListWidget extends StatelessWidget {
  const _ListWidget({
    required this.client,
  });

  final Client client;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatListController>(
      id: 'chatlist',
      builder: (ChatListController controller) {
        if (!controller.initialLoaded) {
          return Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Text(
                AppLocalizations.of(context)!.loadingConvo,
              ),
            ),
          );
        }
        return ImplicitlyAnimatedReorderableList<JoinedRoom>(
          header: _InviteListView(client: client),
          items: controller.showSearch
              ? controller.searchData
              : controller.joinedRooms,
          areItemsTheSame: (a, b) =>
              a.conversation.getRoomId() == b.conversation.getRoomId(),
          // Remember to update the underlying data when the list has been reordered.
          onReorderFinished: (item, from, to, newItems) =>
              controller.moveItem(from, to),
          itemBuilder: (context, itemAnimation, item, index) => Reorderable(
            key: ValueKey(item),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final elevation = lerpDouble(0, 8, t);
              final color = Color.lerp(
                Colors.white,
                Colors.white.withOpacity(0.8),
                t,
              );
              return SizeFadeTransition(
                sizeFraction: 0.7,
                curve: Curves.easeInOut,
                animation: itemAnimation,
                child: Material(
                  color: color,
                  elevation: elevation ?? 0.0,
                  type: MaterialType.transparency,
                  child: _JoinedItem(client: client, item: item),
                ),
              );
            },
          ),
          removeItemBuilder: (context, animation, item) => Reorderable(
            key: ValueKey(item),
            builder: (context, animation, inDrag) {
              return FadeTransition(
                opacity: animation,
                child: _JoinedItem(client: client, item: item),
              );
            },
          ),
          updateItemBuilder: (context, itemAnimation, item) => Reorderable(
            key: ValueKey(item),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final elevation = lerpDouble(0, 8, t);
              final color =
                  Color.lerp(Colors.white, Colors.white.withOpacity(0.8), t);
              return SizeFadeTransition(
                sizeFraction: 0.7,
                curve: Curves.easeInOut,
                animation: itemAnimation,
                child: Material(
                  color: color,
                  elevation: elevation ?? 0.0,
                  type: MaterialType.transparency,
                  child: _JoinedItem(client: client, item: item),
                ),
              );
            },
          ),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
        );
      },
    );
  }
}

class _InviteListView extends StatelessWidget {
  const _InviteListView({required this.client});

  final Client client;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatListController>(
      id: 'invited_list',
      builder: (ChatListController controller) {
        if (controller.invitations.isEmpty) {
          return const SizedBox();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                AppLocalizations.of(context)!.invitedRooms,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.invitations.length,
              itemBuilder: (BuildContext context, int index) {
                return _InvitedItem(
                  client: client,
                  item: controller.invitations[index],
                );
              },
            ),
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 18, top: 10),
              child: Text(
                AppLocalizations.of(context)!.joinedRooms,
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

class _InvitedItem extends StatelessWidget {
  const _InvitedItem({
    required this.client,
    required this.item,
  });

  final Client client;
  final Invitation item;

  @override
  Widget build(BuildContext context) {
    return InviteInfoCard(
      client: client,
      invitation: item,
      avatarColor: Colors.white,
    );
  }
}

class _JoinedItem extends StatelessWidget {
  const _JoinedItem({
    required this.client,
    required this.item,
  });
  final Client client;
  final JoinedRoom item;

  @override
  Widget build(BuildContext context) {
    RoomId roomId = item.conversation.getRoomId();
    // we should be able to update only changed room items
    // so we use GetBuilder to render item
    return GetBuilder<ChatListController>(
      id: 'chatroom-$roomId',
      builder: (controller) => ListItem(
        key: Key(roomId.toString()),
        client: client,
        room: item,
      ),
    );
  }
}
