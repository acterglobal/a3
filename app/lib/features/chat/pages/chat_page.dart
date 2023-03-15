import 'dart:ui';

import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/widgets/invite_info_card.dart';
import 'package:acter/features/chat/widgets/list_item.dart';
import 'package:acter/models/JoinedRoom.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

class ChatPage extends StatefulWidget {
  final Client client;

  const ChatPage({Key? key, required this.client}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ChatListController>(
        id: 'chatlist',
        builder: (controller) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: false,
                snap: false,
                floating: true,
                leading: TextButton(
                  onPressed: () {},
                  child: Container(
                    margin: const EdgeInsets.only(right: 15),
                    child: Text(
                      AppLocalizations.of(context)!.chat,
                      style: AppCommonTheme.appBarTitleStyle,
                    ),
                  ),
                ),
                leadingWidth: 100,
                actions: [
                  IconButton(
                    onPressed: () => controller.toggleSearchView(),
                    padding: const EdgeInsets.only(right: 10, left: 5),
                    icon: const Icon(
                      FlutterIcons.search1_ant,
                      color: AppCommonTheme.svgIconColor,
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
                      FlutterIcons.select_mco,
                      color: AppCommonTheme.svgIconColor,
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
                      FlutterIcons.md_add_ion,
                      color: AppCommonTheme.svgIconColor,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (controller.showSearch)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 5,
                          bottom: 6,
                          left: 10,
                          right: 10,
                        ),
                        child: TextField(
                          onChanged: (value) {
                            controller.searchedData(
                              value,
                              controller.joinedRooms,
                            );
                          },
                          controller: controller.searchController,
                          style: ToDoTheme.taskTitleTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: ToDoTheme.primaryTextColor,
                          decoration: InputDecoration(
                            hintStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                      ),
                    if (widget.client.isGuest())
                      empty
                    else
                      _ListWidget(client: widget.client),
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
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: AppCommonTheme.backgroundColor,
              child: Text(
                AppLocalizations.of(context)!.loadingConvo,
                style: ChatTheme01.emptyMsgTitle,
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
                style: AppCommonTheme.appBarTitleStyle.copyWith(fontSize: 16),
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
                style: AppCommonTheme.appBarTitleStyle.copyWith(fontSize: 16),
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
    String roomId = item.conversation.getRoomId();
    // we should be able to update only changed room items
    // so we use GetBuilder to render item
    return GetBuilder<ChatListController>(
      id: 'chatroom-$roomId',
      builder: (controller) => ListItem(
        key: Key(roomId),
        client: client,
        room: item,
      ),
    );
  }
}
