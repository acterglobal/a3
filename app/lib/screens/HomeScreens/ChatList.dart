// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sized_box_for_whitespace, prefer_final_fields, prefer_typing_uninitialized_variables

import 'dart:math';
import 'dart:ui';
import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/ChatOverview.dart';
import 'package:effektio/common/widget/InviteInfoWidget.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' show Client;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:themed/themed.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late final countInvites;
  String userId = '';
  Random random = Random();
  ChatListController _chatListController = Get.put(ChatListController());

  @override
  void initState() {
    super.initState();
    //setting random invites
    countInvites = random.nextInt(5) + 1;
    getUserId();
    if (!widget.client.isGuest()) {
      widget.client.conversationsRx().listen((event) async {
        _chatListController.updateList(event.toList(), userId);
      });
      widget.client.typingEventRx()?.listen((event) {
        String roomId = event.roomId();
        List<String> userIds = [];
        for (final userId in event.userIds()) {
          userIds.add(userId.toDartString());
        }
        debugPrint('typing event ' + roomId + ': ' + userIds.join(', '));
      });
      widget.client.receiptEventRx()?.listen((event) {
        for (var record in event.userReceipts()) {
          String recordUserId = record.userId();
          if (recordUserId != userId.toString()) {
            debugPrint('receipt event for ' + event.roomId());
            debugPrint('event id: ' + record.eventId());
            debugPrint('user id: ' + recordUserId);
            int? ts = record.ts();
            if (ts != null) {
              debugPrint('timestamp: ' + ts.toString());
            }
          }
        }
      });
    }
  }

  Future<void> getUserId() async {
    await widget.client.userId().then((id) {
      setState(() {
        userId = id.toString();
      });
    });
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
        onReorderFinished: (roomItem, from, to, newRoomItems) =>
            controller.sortList(from, to, roomItem),
        itemBuilder: (context, itemAnimation, roomItem, index) => Reorderable(
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
                  room: roomItem.conversation,
                  user: userId,
                  latestMessage: roomItem.latestMessage,
                ),
              ),
            );
          },
        ),
        removeItemBuilder: (context, animation, roomItem) => Reorderable(
          key: UniqueKey(),
          builder: (context, animation, inDrag) {
            return FadeTransition(
              opacity: animation,
              child: ChatListItem(
                room: roomItem.conversation,
                user: userId,
                latestMessage: roomItem.latestMessage,
              ),
            );
          },
        ),
        updateItemBuilder: (context, itemAnimation, roomItem) => Reorderable(
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
                  room: roomItem.conversation,
                  user: userId,
                  latestMessage: roomItem.latestMessage,
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
