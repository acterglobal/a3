import 'dart:math';
import 'dart:ui';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/ChatListItem.dart';
import 'package:effektio/widgets/InviteInfoWidget.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, UserId;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:themed/themed.dart';

class ChatOverview extends StatefulWidget {
  final Client client;

  const ChatOverview({Key? key, required this.client}) : super(key: key);

  @override
  State<ChatOverview> createState() => _ChatOverviewState();
}

class _ChatOverviewState extends State<ChatOverview> {
  late int _countInvites;
  Random _random = Random();

  @override
  void initState() {
    super.initState();
    //setting random invites
    _countInvites = _random.nextInt(5) + 1;
    Get.put(ChatListController(client: widget.client));
    widget.client.userId().then((UserId uid) {
      String userId = uid.toString();
      Get.put(ChatRoomController(client: widget.client, userId: userId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            leading: TextButton(
              onPressed: () {},
              child: Container(
                margin: const EdgeInsets.only(right: 15),
                child: Text(
                  AppLocalizations.of(context)!.select,
                  style:
                      ChatTheme01.chatTitleStyle + AppCommonTheme.primaryColor,
                ),
              ),
            ),
            leadingWidth: 100,
            actions: [
              IconButton(
                onPressed: () {},
                padding: const EdgeInsets.only(right: 10),
                icon: SvgPicture.asset(
                  'assets/images/edit.svg',
                  color: AppCommonTheme.svgIconColor,
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(left: 18),
                  child: Text(
                    AppLocalizations.of(context)!.chat,
                    style: AppCommonTheme.appBarTitleStyle,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(
                        AppLocalizations.of(context)!.invites,
                        style: AppCommonTheme.appBarTitleStyle
                            .copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    widget.client.isGuest()
                        ? const SizedBox()
                        : GetBuilder<ChatListController>(
                            id: 'chatlist',
                            builder: (ChatListController controller) {
                              return _buildJoinedList(context, controller);
                            },
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitedItem(BuildContext context, int index) {
    return InviteInfoWidget(
      avatarColor: Colors.white,
      inviter: inviters[_random.nextInt(inviters.length)],
      groupName: groups[_random.nextInt(groups.length)],
    );
  }

  Widget _buildJoinedList(BuildContext context, ChatListController controller) {
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
    return ImplicitlyAnimatedReorderableList<RoomItem>(
      header: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _countInvites,
        itemBuilder: _buildInvitedItem,
      ),
      items: controller.roomItems,
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
              child: ChatListItem(
                room: item.conversation,
                latestMessage: item.latestMessage,
              ),
            ),
          );
        },
      ),
      removeItemBuilder: (context, animation, item) => Reorderable(
        key: UniqueKey(),
        builder: (context, animation, inDrag) {
          return FadeTransition(
            opacity: animation,
            child: ChatListItem(
              room: item.conversation,
              latestMessage: item.latestMessage,
            ),
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
              child: ChatListItem(
                room: item.conversation,
                latestMessage: item.latestMessage,
              ),
            ),
          );
        },
      ),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
    );
  }
}
