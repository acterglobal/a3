// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sized_box_for_whitespace, prefer_final_fields, prefer_typing_uninitialized_variables

import 'dart:math';
import 'dart:ui';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/widgets/ChatListItem.dart';
import 'package:effektio/widgets/InviteInfoWidget.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' show Client;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:themed/themed.dart';

class ChatOverview extends StatefulWidget {
  const ChatOverview({Key? key, required this.client}) : super(key: key);

  final Client client;

  @override
  State<ChatOverview> createState() => _ChatOverviewState();
}

class _ChatOverviewState extends State<ChatOverview> {
  late final String user;
  late final countInvites;
  String userId = '';
  Random random = Random();

  @override
  void initState() {
    _fetchUserId();
    super.initState();
    //setting random invites
    countInvites = random.nextInt(5) + 1;

    Get.put(ChatListController(client: widget.client));
  }

  Future<void> _fetchUserId() async {
    var uid = await widget.client.userId();
    setState(() => userId = uid.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            leading: TextButton(
              onPressed: () {},
              child: Container(
                margin: EdgeInsets.only(right: 15),
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
                padding: EdgeInsets.only(right: 10),
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
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 18),
                    child: Text(
                      AppLocalizations.of(context)!.chat,
                      style: AppCommonTheme.appBarTitleStyle,
                    ),
                  ),
                  SizedBox(height: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(left: 18),
                        child: Text(
                          AppLocalizations.of(context)!.invites,
                          style: AppCommonTheme.appBarTitleStyle
                              .copyWith(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 10),
                      widget.client.isGuest()
                          ? const SizedBox()
                          : GetBuilder<ChatListController>(
                              id: 'chatlist',
                              builder: (ChatListController controller) {
                                return buildJoinedList(context, controller);
                              },
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInvitedItem(BuildContext context, int index) {
    return Container(
      child: InviteInfoWidget(
        avatarColor: Colors.white,
        inviter: inviters[random.nextInt(inviters.length)],
        groupName: groups[random.nextInt(groups.length)],
      ),
    );
  }

  Widget buildJoinedList(BuildContext context, ChatListController controller) {
    if (controller.initialLoaded) {
      return ImplicitlyAnimatedReorderableList<RoomItem>(
        header: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: countInvites,
          itemBuilder: buildInvitedItem,
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
                child: GetBuilder<ChatListController>(
                  id: item.conversation.getRoomId(),
                  builder: (ChatListController controller) {
                    return ChatListItem(
                      key: Key(item.conversation.getRoomId()),
                      room: item.conversation,
                      user: userId,
                      latestMessage: item.latestMessage,
                      client: widget.client,
                      typingUsers: controller.typingUsers,
                    );
                  },
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
              child: GetBuilder<ChatListController>(
                id: item.conversation.getRoomId(),
                builder: (ChatListController controller) {
                  return ChatListItem(
                    key: Key(item.conversation.getRoomId()),
                    room: item.conversation,
                    user: user,
                    latestMessage: item.latestMessage,
                    client: widget.client,
                    typingUsers: controller.typingUsers,
                  );
                },
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
                child: GetBuilder<ChatListController>(
                  id: item.conversation.getRoomId(),
                  builder: (ChatListController controller) {
                    return ChatListItem(
                      key: Key(item.conversation.getRoomId()),
                      room: item.conversation,
                      user: user,
                      latestMessage: item.latestMessage,
                      client: widget.client,
                      typingUsers: controller.typingUsers,
                    );
                  },
                ),
              ),
            );
          },
        ),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
      );
    } else {
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
  }
}
