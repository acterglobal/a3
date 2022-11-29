import 'package:bubble/bubble.dart';
import 'package:effektio/common/constants.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/EmojiReactionListItem.dart';
import 'package:effektio/widgets/emoji_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';

import 'package:effektio/controllers/chat_room_controller.dart';

class ChatBubbleBuilder extends StatefulWidget {
  final String userId;
  final Widget child;
  final types.Message message;
  final bool nextMessageInGroup;

  const ChatBubbleBuilder({
    Key? key,
    required this.child,
    required this.message,
    required this.nextMessageInGroup,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatBubbleBuilder> createState() => _ChatBubbleBuilderState();
}

class _ChatBubbleBuilderState extends State<ChatBubbleBuilder>
    with SingleTickerProviderStateMixin {
  late types.MessageType messagetype;
  final ChatRoomController roomController = Get.find<ChatRoomController>();
  late final TabController tabBarController;

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(length: 3, vsync: this);
    messagetype = widget.message.type;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatRoomController>(
      id: 'emoji-reaction',
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 6),
            Row(
              textDirection: widget.userId != widget.message.author.id
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              children: [
                Flexible(
                  child: Stack(
                    children: <Widget>[
                      buildChatBubble(),
                      buildEmojiRow(),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onLongPress: () =>
                  roomController.updateEmojiState(widget.message),
              child: Align(
                alignment: widget.userId != widget.message.author.id
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                child: buildEmojiContainer(20),
              ),
            ),
          ],
        );
      },
    );
  }

//Emoji reaction info bottom sheet.
  void showEmojiReactionsSheet() {
    showModalBottomSheet(
      backgroundColor: AppCommonTheme.backgroundColorLight,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TabBar(
                overlayColor:
                    MaterialStateProperty.all<Color>(Colors.transparent),
                padding: const EdgeInsets.all(24),
                controller: tabBarController,
                indicator: const BoxDecoration(
                  color: AppCommonTheme.backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                tabs: const [
                  Tab(
                    text: ('All 15'),
                  ),
                  Tab(
                    text: ('$heart +11'),
                  ),
                  Tab(
                    text: ('$faceWithTears +3'),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TabBarView(
                  controller: tabBarController,
                  children: [
                    buildReactionListing(astonishedFace),
                    buildReactionListing(heart),
                    buildReactionListing(faceWithTears),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }

//Custom chat bubble
  Widget buildChatBubble() {
    return Bubble(
      child: widget.child,
      color: widget.userId != widget.message.author.id ||
              messagetype == types.MessageType.image
          ? AppCommonTheme.backgroundColorLight
          : AppCommonTheme.primaryColor,
      margin: widget.nextMessageInGroup
          ? const BubbleEdges.symmetric(
              horizontal: 2,
            )
          : null,
      radius: const Radius.circular(18),
      padding: messagetype == types.MessageType.image
          ? const BubbleEdges.all(0)
          : null,
      nip: (widget.nextMessageInGroup || messagetype == types.MessageType.image)
          ? BubbleNip.no
          : widget.userId != widget.message.author.id
              ? BubbleNip.leftBottom
              : BubbleNip.rightBottom,
      nipHeight: 18,
      nipWidth: 0.5,
      nipRadius: 0,
    );
  }

  //Emoji Container which shows message reactions
  Widget buildEmojiContainer(int emojisCount) {
    return Container(
      width: emojisCount * 50,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppCommonTheme.dividerColor,
          width: 0.2,
        ),
        borderRadius: BorderRadius.only(
          topLeft: widget.nextMessageInGroup
              ? const Radius.circular(12)
              : widget.userId != widget.message.author.id
                  ? const Radius.circular(0)
                  : const Radius.circular(12),
          topRight: widget.nextMessageInGroup
              ? const Radius.circular(12)
              : widget.userId != widget.message.author.id
                  ? const Radius.circular(12)
                  : const Radius.circular(0),
          bottomLeft: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        ),
        color: ChatTheme01.chatEmojiContainerColor,
      ),
      padding: const EdgeInsets.all(5),
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 5.0,
        runSpacing: 3.0,
        children: List.generate(
          emojisCount,
          (_) => GestureDetector(
            onTap: () {
              showEmojiReactionsSheet();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  heart,
                  style: ChatTheme01.emojiCountStyle,
                ),
                SizedBox(
                  width: 2.0,
                ),
                Text(
                  '+12',
                  style: ChatTheme01.emojiCountStyle,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Emoji Row to select emoji reaction
  Widget buildEmojiRow() {
    return Visibility(
      visible: roomController.emojiCurrentId == widget.message.id &&
              roomController.isEmojiContainerVisible
          ? true
          : false,
      child: Container(
        width: 198,
        height: 42,
        padding: const EdgeInsets.all(8.0),
        margin: widget.userId != widget.message.author.id
            ? const EdgeInsets.only(bottom: 8.0, left: 8.0)
            : const EdgeInsets.only(bottom: 8.0, right: 8.0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(20.0),
          ),
          color: AppCommonTheme.backgroundColor,
          border: Border.all(
            color: AppCommonTheme.dividerColor,
            width: 0.5,
          ),
        ),
        child: EmojiRow(
          onEmojiTap: (String value) {
            roomController.toggleEmojiContainer();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$value tapped'),
                backgroundColor: AuthTheme.authSuccess,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildReactionListing(String emoji) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: 10,
      itemBuilder: (_, index) {
        return EmojiReactionListItem(emoji: emoji);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(
          height: 12,
        );
      },
    );
  }
}
