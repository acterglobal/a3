// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sized_box_for_whitespace, prefer_final_fields, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/ChatOverview.dart';
import 'package:effektio/common/widget/InviteInfoWidget.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, FfiListConversation, RoomMessage;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:themed/themed.dart';

class RoomData {
  String roomId;
  Conversation conversation;
  RecentMessage? recentMessage;

  RoomData({
    required this.roomId,
    required this.conversation,
    this.recentMessage,
  });
}

class ChatList extends StatefulWidget {
  const ChatList({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late final String user;
  late final countInvites;
  Random random = Random();
  late final Stream<FfiListConversation> stream;
  late final StreamSubscription<FfiListConversation> subscription;
  List<RoomData> roomDatas = [];
  bool initialLoaded = false;

  @override
  void initState() {
    //setting random invites
    countInvites = random.nextInt(5) + 1;
    super.initState();
    _getUser();

    stream = widget.client.conversationsRx();
    subscription = stream.listen((event) {
      if (!initialLoaded) {
        setState(() => initialLoaded = true);
      }
      List<RoomData> newRoomDatas = [];
      for (Conversation convo in event.toList()) {
        String roomId = convo.getRoomId();
        int oldIndex = roomDatas.indexWhere((x) => x.roomId == roomId);
        RoomMessage? msg = convo.latestMessage();
        if (msg == null) {
          // prevent latest message from deleting
          RoomData newRoomData = RoomData(
            roomId: roomId,
            conversation: convo,
            recentMessage:
                oldIndex == -1 ? null : roomDatas[oldIndex].recentMessage,
          );
          newRoomDatas.add(newRoomData);
          continue;
        }
        RoomData newRoomData = RoomData(
          roomId: roomId,
          conversation: convo,
          recentMessage: RecentMessage(
            sender: msg.sender(),
            body: msg.body(),
            originServerTs: msg.originServerTs(),
          ),
        );
        newRoomDatas.add(newRoomData);
      }
      setState(() => roomDatas = newRoomDatas);
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<void> _getUser() async {
    var userId = await widget.client.userId();
    user = userId.toString();
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
                      buildJoinedList(context),
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

  Widget buildJoinedList(BuildContext context) {
    if (initialLoaded) {
      return ImplicitlyAnimatedReorderableList<RoomData>(
        header: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: countInvites,
          itemBuilder: buildInvitedItem,
        ),
        items: roomDatas,
        areItemsTheSame: (a, b) => a.roomId == b.roomId,
        onReorderFinished: (item, from, to, newItems) {
          // Remember to update the underlying data when the list has been reordered.
          setState(() {
            roomDatas
              ..removeAt(from)
              ..insert(to, item);
          });
        },
        itemBuilder: (context, itemAnimation, item, index) => Reorderable(
          key: ValueKey(item.roomId),
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
                  user: user,
                  recentMessage: item.recentMessage,
                ),
              ),
            );
          },
        ),
        removeItemBuilder: (context, animation, item) => Reorderable(
          key: ValueKey(item.roomId),
          builder: (context, animation, inDrag) {
            return FadeTransition(
              opacity: animation,
              child: ChatListItem(
                room: item.conversation,
                user: user,
                recentMessage: item.recentMessage,
              ),
            );
          },
        ),
        updateItemBuilder: (context, itemAnimation, item) => Reorderable(
          key: ValueKey(item.roomId),
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
                  user: user,
                  recentMessage: item.recentMessage,
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
