import 'dart:convert';
import 'dart:typed_data';

import 'package:bubble/bubble.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/EmojiReactionListItem.dart';
import 'package:effektio/widgets/emoji_row.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show ReactionDesc;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_html/flutter_html.dart';
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
    with TickerProviderStateMixin {
  final ChatRoomController roomController = Get.find<ChatRoomController>();
  late TabController tabBarController;
  List<Tab> reactionTabs = [];

  @override
  void initState() {
    super.initState();

    tabBarController = TabController(length: reactionTabs.length, vsync: this);
  }

  // A helper function to get bubble widget size to set constraints beforehand
  //for emoji container.

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatRoomController>(
      id: 'emoji-reaction',
      builder: (ChatRoomController controller) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment:
              isAuthor() ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                buildChatBubble(),
                buildEmojiRow(),
              ],
            ),
            Align(
              alignment:
                  !isAuthor() ? Alignment.bottomLeft : Alignment.bottomRight,
              child: buildEmojiContainer(),
            ),
          ],
        );
      },
    );
  }

  //Emoji reaction info bottom sheet.
  void showEmojiReactionsSheet(Map<String, dynamic> reactions) {
    List<String> keys = reactions.keys.toList();
    num count = 0;
    setState(() {
      reactions.forEach((key, value) {
        count += value.count();
        reactionTabs.add(Tab(text: '$key+${value.count()}'));
      });
      reactionTabs.insert(0, (Tab(text: 'All $count')));
      tabBarController =
          TabController(length: reactionTabs.length, vsync: this);
    });
    showModalBottomSheet(
      backgroundColor: AppCommonTheme.backgroundColorLight,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: true,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TabBar(
                isScrollable: true,
                overlayColor:
                    MaterialStateProperty.all<Color>(Colors.transparent),
                padding: const EdgeInsets.all(24),
                controller: tabBarController,
                indicator: const BoxDecoration(
                  color: AppCommonTheme.backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                tabs: reactionTabs,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TabBarView(
                  viewportFraction: 1.0,
                  controller: tabBarController,
                  children: [
                    buildReactionListing(keys),
                    for (var count in keys) buildReactionListing([count]),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      setState(() {
        reactionTabs.clear();
      });
    });
  }

  // Custom chat bubble
  Widget buildChatBubble() {
    return GestureDetector(
      onLongPress: () {
        roomController.updateEmojiState(widget.message);
        roomController.replyMessageWidget = widget.child;
        roomController.repliedToMessage = widget.message;
      },
      child: Column(
        crossAxisAlignment:
            isAuthor() ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          (widget.message.repliedMessage != null)
              ? widget.userId == widget.message.repliedMessage!.author.id
                  ? const Text(
                      'Replied to yourself',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    )
                  : Text(
                      roomController.client.userId().toString() ==
                              widget.message.repliedMessage!.author.id
                          ? 'Replied to you'
                          : 'Replied to ${widget.message.repliedMessage!.author.id}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    )
              : const SizedBox(),
          const SizedBox(height: 8),
          (widget.message.repliedMessage != null)
              ? buildOriginalBubble(widget.message)
              : const SizedBox(),
          const SizedBox(height: 4),
          Bubble(
            child: widget.child,
            color: !isAuthor() || widget.message is types.ImageMessage
                ? AppCommonTheme.backgroundColorLight
                : AppCommonTheme.primaryColor,
            margin: widget.nextMessageInGroup
                ? const BubbleEdges.symmetric(horizontal: 2)
                : null,
            radius: const Radius.circular(22),
            padding: widget.message is types.ImageMessage
                ? const BubbleEdges.all(0)
                : null,
            nip: (widget.nextMessageInGroup ||
                    widget.message is types.ImageMessage)
                ? BubbleNip.no
                : !isAuthor()
                    ? BubbleNip.leftBottom
                    : BubbleNip.rightBottom,
            nipHeight: 18,
            nipWidth: 0.5,
            nipRadius: 0,
          ),
        ],
      ),
    );
  }

  //Custom original bubble
  Widget buildOriginalBubble(types.Message message) {
    return Bubble(
      child: originalMessageBuilder(message),
      color: AppCommonTheme.backgroundColorLight,
      margin: widget.nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 2)
          : null,
      radius: const Radius.circular(22),
      padding: message.repliedMessage is types.ImageMessage
          ? const BubbleEdges.all(0)
          : null,
      nip: BubbleNip.no,
    );
  }

  Widget originalMessageBuilder(types.Message message) {
    if (message.repliedMessage is types.TextMessage) {
      return Html(
        data: """${message.repliedMessage!.metadata?['content']}""",
        shrinkWrap: true,
        style: {
          'body': Style(
            color: ChatTheme01.chatReplyTextColor,
            fontWeight: FontWeight.w400,
            fontSize: FontSize(14),
          ),
        },
      );
    } else if (message.repliedMessage is types.ImageMessage) {
      Uint8List data =
          base64Decode(message.repliedMessage!.metadata?['content']);
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: data.isNotEmpty
            ? Image.memory(
                data,
                errorBuilder:
                    (BuildContext context, Object url, StackTrace? error) {
                  return Text('Could not load image due to $error');
                },
                cacheHeight: 75,
                cacheWidth: 75,
                fit: BoxFit.cover,
              )
            : const SizedBox(),
      );
    } else if (message.repliedMessage is types.FileMessage) {
      return Text(
        message.repliedMessage!.metadata?['content'],
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );
    } else {
      return const SizedBox();
    }
  }

  //Emoji Container which shows message reactions
  Widget buildEmojiContainer() {
    List<String> keys = [];
    if (widget.message.metadata != null) {
      if (widget.message.metadata!.containsKey('reactions')) {
        Map<String, dynamic> reactions = widget.message.metadata!['reactions'];
        keys = reactions.keys.toList();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth / 3),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: keys.isEmpty
                ? null
                : Border.all(color: AppCommonTheme.dividerColor, width: 0.2),
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
            children: List.generate(keys.length, (int index) {
              String key = keys[index];
              Map<String, dynamic> reactions =
                  widget.message.metadata!['reactions'];
              ReactionDesc? desc = reactions[key];
              int count = desc!.count();
              return GestureDetector(
                onTap: () {
                  showEmojiReactionsSheet(reactions);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(key, style: ChatTheme01.emojiCountStyle),
                    const SizedBox(width: 2),
                    Text(count.toString(), style: ChatTheme01.emojiCountStyle),
                  ],
                ),
              );
            }),
          ),
        );
      },
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
          onEmojiTap: (String value) async {
            await roomController.sendEmojiReaction(
              roomController.repliedToMessage!.id,
              value,
            );
          },
        ),
      ),
    );
  }

  Widget buildReactionListing(List<String> emojis) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: emojis.length,
      itemBuilder: (BuildContext context, int index) {
        return EmojiReactionListItem(emoji: emojis[index]);
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
