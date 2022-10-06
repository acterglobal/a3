import 'dart:ui';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/invitation_controller.dart';
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
  late String userId;
  final InvitationController _invitationController =
      Get.find<InvitationController>();

  @override
  void initState() {
    super.initState();
    userId = widget.client.userId().toString();
    Get.put(ChatListController(client: widget.client));
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
                _buildList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(BuildContext context) {
    if (_invitationController.eventList.isEmpty) {
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
          itemCount: _invitationController.eventList.length,
          itemBuilder: (BuildContext context, int index) => InviteInfoWidget(
            avatarColor: Colors.white,
            inviter: _invitationController.eventList[index].sender(),
            groupName: _invitationController.eventList[index].roomName(),
          ),
        ),
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            AppLocalizations.of(context)!.joinedRooms,
            style: AppCommonTheme.appBarTitleStyle.copyWith(fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (widget.client.isGuest()) {
      return const SizedBox();
    }
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
        return ImplicitlyAnimatedReorderableList<RoomItem>(
          header: _buildListHeader(context),
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
                    userId: userId,
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
                  userId: userId,
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
                    userId: userId,
                    latestMessage: item.latestMessage,
                  ),
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
