import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:acter/common/themes/app_theme.dart';
import 'package:bubble/bubble.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/widgets/emoji_reaction_item.dart';
import 'package:acter/features/chat/widgets/emoji_row.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ReactionDesc;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:get/get.dart';

class BubbleBuilder extends StatelessWidget {
  final String userId;
  final Widget child;
  final types.Message message;
  final bool nextMessageInGroup;
  final bool enlargeEmoji;

  const BubbleBuilder({
    Key? key,
    required this.child,
    required this.message,
    required this.nextMessageInGroup,
    required this.userId,
    required this.enlargeEmoji,
  }) : super(key: key);

  bool isAuthor() {
    return userId == message.author.id;
  }

  @override
  Widget build(BuildContext context) {
    String msgType = '';
    if (message.metadata!.containsKey('eventType')) {
      msgType = message.metadata?['eventType'];
    }
    bool isMemberEvent = msgType == 'm.room.member';
    return GetBuilder<ChatRoomController>(
      id: 'emoji-reaction',
      builder: (ChatRoomController controller) {
        return Column(
          crossAxisAlignment:
              isAuthor() ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ChatBubble(
                  controller: controller,
                  isAuthor: isAuthor(),
                  userId: userId,
                  message: message,
                  nextMessageInGroup: nextMessageInGroup,
                  child: child,
                  enlargeEmoji: enlargeEmoji,
                  isMemberEvent: isMemberEvent,
                ),
                !isMemberEvent
                    ? _EmojiRow(
                        controller: controller,
                        isAuthor: isAuthor(),
                        message: message,
                      )
                    : const SizedBox.shrink()
              ],
            ),
            !isMemberEvent
                ? Align(
                    alignment: !isAuthor()
                        ? Alignment.bottomLeft
                        : Alignment.bottomRight,
                    child: _EmojiContainer(
                      isAuthor: isAuthor(),
                      message: message,
                      nextMessageInGroup: nextMessageInGroup,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatRoomController controller;
  final bool isAuthor;
  final String userId;
  final types.Message message;
  final bool nextMessageInGroup;
  final Widget child;
  final bool enlargeEmoji;
  final bool isMemberEvent;

  const _ChatBubble({
    required this.controller,
    required this.isAuthor,
    required this.userId,
    required this.message,
    required this.nextMessageInGroup,
    required this.child,
    required this.enlargeEmoji,
    required this.isMemberEvent,
  });

  @override
  Widget build(BuildContext context) {
    String msgType = '';
    if (message.metadata!.containsKey('eventType')) {
      msgType = message.metadata?['eventType'];
    }
    bool isMemberEvent = msgType == 'm.room.member';
    String myId = controller.client.userId().toString();
    return GestureDetector(
      onLongPress: isMemberEvent
          ? null
          : () {
              controller.updateEmojiState(message);
              controller.replyMessageWidget = child;
              controller.repliedToMessage = message;
            },
      child: Column(
        crossAxisAlignment:
            isAuthor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          (message.repliedMessage != null)
              ? Text(
                  myId == message.repliedMessage!.author.id
                      ? 'Replied to you'
                      : 'Replied to ${message.repliedMessage!.author.id}',
                  style: Theme.of(context).textTheme.labelSmall,
                )
              : const SizedBox(),
          const SizedBox(height: 8),
          //reply bubble
          (message.repliedMessage != null)
              ? Bubble(
                  color: Theme.of(context).colorScheme.neutral,
                  child: _OriginalMessageBuilder(message: message),
                  margin: nextMessageInGroup
                      ? const BubbleEdges.symmetric(horizontal: 2)
                      : null,
                  radius: const Radius.circular(22),
                  padding: message.repliedMessage is types.ImageMessage
                      ? const BubbleEdges.all(0)
                      : null,
                  nip: BubbleNip.no,
                )
              : const SizedBox(),
          const SizedBox(height: 4),
          (enlargeEmoji || isMemberEvent)
              ? child
              : Bubble(
                  color: myId == message.author.id
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  child: child,
                  style: BubbleStyle(
                    margin: nextMessageInGroup
                        ? const BubbleEdges.symmetric(horizontal: 2)
                        : null,
                    radius: const Radius.circular(22),
                    padding: message is types.ImageMessage
                        ? const BubbleEdges.all(0)
                        : null,
                    nip: (nextMessageInGroup || message is types.ImageMessage)
                        ? BubbleNip.no
                        : !isAuthor
                            ? BubbleNip.leftBottom
                            : BubbleNip.rightBottom,
                    nipHeight: 18,
                    nipWidth: 0.5,
                    nipRadius: 0,
                  ),
                ),
        ],
      ),
    );
  }
}

class _EmojiContainer extends StatefulWidget {
  const _EmojiContainer({
    required this.isAuthor,
    required this.message,
    required this.nextMessageInGroup,
  });
  final bool isAuthor;
  final types.Message message;
  final bool nextMessageInGroup;

  @override
  State<_EmojiContainer> createState() => _EmojiContainerState();
}

class _EmojiContainerState extends State<_EmojiContainer>
    with TickerProviderStateMixin {
  late TabController tabBarController;
  List<Tab> reactionTabs = [];

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(length: reactionTabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
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
            borderRadius: BorderRadius.only(
              topLeft: widget.nextMessageInGroup
                  ? const Radius.circular(12)
                  : !widget.isAuthor
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
              topRight: widget.nextMessageInGroup
                  ? const Radius.circular(12)
                  : !widget.isAuthor
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
              bottomLeft: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
            ),
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
                    Text(key),
                    const SizedBox(width: 2),
                    Text(count.toString()),
                  ],
                ),
              );
            }),
          ),
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
        reactionTabs.add(
          Tab(
            text: '$key+${value.count()}',
          ),
        );
      });
      reactionTabs.insert(0, (Tab(text: 'All $count')));
      tabBarController =
          TabController(length: reactionTabs.length, vsync: this);
    });
    showModalBottomSheet(
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
                padding: const EdgeInsets.all(24),
                controller: tabBarController,
                overlayColor:
                    MaterialStateProperty.all<Color>(Colors.transparent),
                indicator: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                dividerColor: Colors.transparent,
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
                    _ReactionListing(emojis: keys),
                    for (var count in keys) _ReactionListing(emojis: [count]),
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
}

class _EmojiRow extends StatelessWidget {
  const _EmojiRow({
    required this.controller,
    required this.isAuthor,
    required this.message,
  });
  final ChatRoomController controller;
  final bool isAuthor;
  final types.Message message;

  @override
  Widget build(BuildContext context) {
    final ChatRoomController controller = Get.find<ChatRoomController>();
    return Visibility(
      visible: controller.emojiCurrentId == message.id &&
          controller.isEmojiContainerVisible,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 202, maxHeight: 42),
        padding: const EdgeInsets.all(8),
        margin: !isAuthor
            ? const EdgeInsets.only(bottom: 8, left: 8)
            : const EdgeInsets.only(bottom: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: Theme.of(context).colorScheme.neutral2,
        ),
        child: EmojiRow(
          onEmojiTap: (String value) async {
            await controller.sendEmojiReaction(
              controller.repliedToMessage!.id,
              value,
            );
            controller.updateEmojiState(message);
          },
        ),
      ),
    );
  }
}

class _OriginalMessageBuilder extends StatelessWidget {
  const _OriginalMessageBuilder({
    required this.message,
  });

  final types.Message message;

  @override
  Widget build(BuildContext context) {
    if (message.repliedMessage is types.TextMessage) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              sqrt(message.repliedMessage!.metadata!['messageLength']) * 38.5,
          maxHeight: double.infinity,
        ),
        child: Html(
          data: """${message.repliedMessage!.metadata?['content']}""",
          padding: const EdgeInsets.all(8),
          defaultTextStyle: Theme.of(context).textTheme.bodySmall,
        ),
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
        style: Theme.of(context).textTheme.bodySmall,
      );
    } else {
      return const SizedBox();
    }
  }
}

class _ReactionListing extends StatelessWidget {
  const _ReactionListing({
    required this.emojis,
  });

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: emojis.length,
      itemBuilder: (BuildContext context, int index) {
        return EmojiReactionItem(emoji: emojis[index]);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
    );
  }
}
