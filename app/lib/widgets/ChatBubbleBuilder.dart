import 'package:bubble/bubble.dart';
import 'package:effektio/common/constants.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/EmojiReactionListItem.dart';
import 'package:effektio/widgets/emoji_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';

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
      builder: (ChatRoomController controller) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              textDirection:
                  !isAuthor() ? TextDirection.ltr : TextDirection.rtl,
              children: [
                Flexible(
                  child: Stack(
                    children: [
                      buildChatBubble(),
                      buildEmojiRow(),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onLongPress: () {
                roomController.updateEmojiState(widget.message);
              },
              child: Align(
                alignment:
                    !isAuthor() ? Alignment.bottomLeft : Alignment.bottomRight,
                child: buildEmojiContainer(context, 20),
              ),
            ),
          ],
        );
      },
    );
  }

  //Emoji reaction info bottom sheet.
  void showEmojiReactionsSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: AppCommonTheme.backgroundColorLight,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext ctx) {
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
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                tabs: const [
                  Tab(text: 'All 15'),
                  Tab(text: '$heart +11'),
                  Tab(text: '$faceWithTears +3')
                ],
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Column(
      crossAxisAlignment:
          isAuthor() ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'You replied',
        //   style: TextStyle(color: Colors.white, fontSize: 12),
        // ),
        // const SizedBox(height: 8),
        // Bubble(
        //   child: const Padding(
        //     padding: EdgeInsets.all(8),
        //     child: Text(
        //       'This is a reply message demo',
        //       style: ChatTheme01.chatReplyTextStyle,
        //     ),
        //   ),
        //   color: AppCommonTheme.backgroundColorLight,
        //   margin: widget.nextMessageInGroup
        //       ? const BubbleEdges.symmetric(horizontal: 2)
        //       : null,
        //   radius: const Radius.circular(22),
        //   padding: messagetype == types.MessageType.image
        //       ? const BubbleEdges.all(0)
        //       : null,
        //   nip: BubbleNip.no,
        // ),
        // const SizedBox(height: 4),
        Bubble(
          child: widget.child,
          color: !isAuthor() || messagetype == types.MessageType.image
              ? AppCommonTheme.backgroundColorLight
              : AppCommonTheme.primaryColor,
          margin: widget.nextMessageInGroup
              ? const BubbleEdges.symmetric(horizontal: 2)
              : null,
          radius: const Radius.circular(22),
          padding: messagetype == types.MessageType.image
              ? const BubbleEdges.all(0)
              : null,
          nip: (widget.nextMessageInGroup ||
                  messagetype == types.MessageType.image)
              ? BubbleNip.no
              : !isAuthor()
                  ? BubbleNip.leftBottom
                  : BubbleNip.rightBottom,
          nipHeight: 18,
          nipWidth: 0.5,
          nipRadius: 0,
        ),
      ],
    );
  }

  //Custom reply bubble
  Widget buildReplyBubble() {
    return Bubble(
      child: widget.child,
      color: AppCommonTheme.backgroundColorLight,
      margin: widget.nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 2)
          : null,
      radius: const Radius.circular(18),
      padding: messagetype == types.MessageType.image
          ? const BubbleEdges.all(0)
          : null,
      nip: BubbleNip.no,
    );
  }

  //Emoji Container which shows message reactions
  Widget buildEmojiContainer(BuildContext context, int emojisCount) {
    return Container(
      width: emojisCount * 50,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: AppCommonTheme.dividerColor, width: 0.2),
        borderRadius: BorderRadius.only(
          topLeft: widget.nextMessageInGroup
              ? const Radius.circular(12)
              : !isAuthor()
                  ? const Radius.circular(0)
                  : const Radius.circular(12),
          topRight: widget.nextMessageInGroup
              ? const Radius.circular(12)
              : !isAuthor()
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
        spacing: 5,
        runSpacing: 3,
        children: List.generate(emojisCount, (int index) {
          return GestureDetector(
            onTap: () {
              showEmojiReactionsSheet(context);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(heart, style: ChatTheme01.emojiCountStyle),
                SizedBox(width: 2),
                Text('+12', style: ChatTheme01.emojiCountStyle)
              ],
            ),
          );
        }),
      ),
    );
  }

  //Emoji Row to select emoji reaction
  Widget buildEmojiRow() {
    return Visibility(
      visible: roomController.emojiCurrentId == widget.message.id &&
          roomController.isEmojiContainerVisible,
      child: Container(
        width: 198,
        height: 42,
        padding: const EdgeInsets.all(8),
        margin: !isAuthor()
            ? const EdgeInsets.only(bottom: 8, left: 8)
            : const EdgeInsets.only(bottom: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: AppCommonTheme.backgroundColor,
          border: Border.all(color: AppCommonTheme.dividerColor, width: 0.5),
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
      itemBuilder: (BuildContext context, int index) {
        return EmojiReactionListItem(emoji: emoji);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
    );
  }

  bool isAuthor() {
    return widget.userId == widget.message.author.id;
  }
}
