import 'dart:ui';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/ChatListItem.dart';
import 'package:effektio/widgets/InviteInfoWidget.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
// import 'package:themed/themed.dart';

class ChatOverview extends StatefulWidget {
  final Client client;

  const ChatOverview({Key? key, required this.client}) : super(key: key);

  @override
  State<ChatOverview> createState() => _ChatOverviewState();
}

class _ChatOverviewState extends State<ChatOverview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
                onPressed: () {
                  showNotYetImplementedMsg(
                    context,
                    'Chat Search is not implemented yet',
                  );
                },
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.client.isGuest()) buildList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListHeader(BuildContext context) {
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
                return buildInvitedItem(controller.invitations[index]);
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

  Widget buildList(BuildContext context) {
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
          header: buildListHeader(context),
          items: controller.joinedRooms,
          areItemsTheSame: (a, b) =>
              a.conversation.getRoomId() == b.conversation.getRoomId(),
          // Remember to update the underlying data when the list has been reordered.
          onReorderFinished: (item, from, to, newItems) =>
              controller.moveItem(from, to),
          itemBuilder: (context, itemAnimation, item, index) => Reorderable(
            key: UniqueKey(),
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
                  child: buildJoinedItem(item),
                ),
              );
            },
          ),
          removeItemBuilder: (context, animation, item) => Reorderable(
            key: UniqueKey(),
            builder: (context, animation, inDrag) {
              return FadeTransition(
                opacity: animation,
                child: buildJoinedItem(item),
              );
            },
          ),
          updateItemBuilder: (context, itemAnimation, item) => Reorderable(
            key: UniqueKey(),
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
                  child: buildJoinedItem(item),
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

  Widget buildInvitedItem(Invitation item) {
    return InviteInfoWidget(
      userId: widget.client.userId().toString(),
      invitation: item,
      avatarColor: Colors.white,
    );
  }

  Widget buildJoinedItem(JoinedRoom item) {
    // we should be able to update only changed room items
    // so we use GetBuilder to render item
    return GetBuilder<ChatListController>(
      id: 'chatroom-${item.conversation.getRoomId()}',
      builder: (controller) => ChatListItem(
        key: Key(item.conversation.getRoomId()),
        userId: widget.client.userId().toString(),
        room: item.conversation,
        latestMessage: item.latestMessage,
        typingUsers: item.typingUsers,
      ),
    );
  }
}
