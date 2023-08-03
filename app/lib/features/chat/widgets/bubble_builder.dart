import 'dart:convert';
import 'dart:typed_data';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:bubble/bubble.dart';
import 'package:acter/features/chat/widgets/emoji_reaction_item.dart';
import 'package:acter/features/chat/widgets/emoji_row.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ReactionDesc;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_to/swipe_to.dart';

class BubbleBuilder extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    String msgType = '';
    if (message.metadata!.containsKey('eventType')) {
      msgType = message.metadata?['eventType'];
    }
    bool isMemberEvent = msgType == 'm.room.member';

    return isMemberEvent
        ? child
        : SwipeTo(
            onLeftSwipe: !isAuthor()
                ? null
                : () {
                    ref.read(chatInputProvider.notifier).setReplyWidget(child);
                    ref.read(chatRoomProvider.notifier).repliedToMessage =
                        message;
                    if (!ref.read(chatInputProvider).showReplyView) {
                      ref.read(chatInputProvider.notifier).toggleReplyView();
                    }
                  },
            onRightSwipe: isAuthor()
                ? null
                : () {
                    ref.read(chatInputProvider.notifier).setReplyWidget(child);
                    ref.read(chatRoomProvider.notifier).repliedToMessage =
                        message;

                    if (!ref.read(chatInputProvider).showReplyView) {
                      ref.read(chatInputProvider.notifier).toggleReplyView();
                    }
                  },
            child: _ChatBubble(
              isAuthor: isAuthor(),
              message: message,
              nextMessageInGroup: nextMessageInGroup,
              enlargeEmoji: enlargeEmoji,
              child: child,
            ),
          );
  }
}

class _ChatBubble extends ConsumerWidget {
  final bool isAuthor;
  final types.Message message;
  final bool nextMessageInGroup;
  final Widget child;
  final bool enlargeEmoji;

  const _ChatBubble({
    required this.isAuthor,
    required this.message,
    required this.nextMessageInGroup,
    required this.child,
    required this.enlargeEmoji,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment:
          isAuthor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _EmojiRow(
          isAuthor: isAuthor,
          message: message,
        ),
        const SizedBox(height: 4),
        enlargeEmoji
            ? child
            : Bubble(
                color: isAuthor
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Theme.of(context).colorScheme.onPrimary,
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
                child: message.repliedMessage != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .neutral
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 15,
                                  ),
                                  child: Row(
                                    children: [
                                      ActerAvatar(
                                        uniqueId:
                                            message.repliedMessage!.author.id,
                                        mode: DisplayMode.User,
                                        displayName: message
                                            .repliedMessage!.author.firstName,
                                        avatar: ref
                                            .watch(
                                              chatRoomProvider.notifier,
                                            )
                                            .getUserProfile(
                                              message.repliedMessage!.author.id,
                                            )
                                            ?.getAvatarImage(),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${message.repliedMessage?.author.firstName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                _OriginalMessageBuilder(message: message),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          child,
                        ],
                      )
                    : child,
              ),
        Align(
          alignment: !isAuthor ? Alignment.bottomLeft : Alignment.bottomRight,
          child: _EmojiContainer(
            isAuthor: isAuthor,
            message: message,
            nextMessageInGroup: nextMessageInGroup,
          ),
        ),
      ],
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
    if (mounted) {
      setState(() {
        reactions.forEach((key, value) {
          count += value.count();
          reactionTabs.add(
            Tab(text: '$key+${value.count()}'),
          );
        });
        reactionTabs.insert(0, (Tab(text: 'All $count')));
        tabBarController = TabController(
          length: reactionTabs.length,
          vsync: this,
        );
      });
    }
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
      if (mounted) {
        setState(() => reactionTabs.clear());
      }
    });
  }
}

class _EmojiRow extends ConsumerWidget {
  const _EmojiRow({
    required this.isAuthor,
    required this.message,
  });
  final bool isAuthor;
  final types.Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Visibility(
      visible:
          ref.watch(chatRoomProvider.notifier).emojiCurrentId == message.id &&
              ref.watch(chatInputProvider.select((ci) => ci.emojiRowVisible)),
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
            await ref.read(chatRoomProvider.notifier).sendEmojiReaction(
                  ref.read(chatRoomProvider.notifier).repliedToMessage!.id,
                  value,
                );
            ref.read(chatRoomProvider.notifier).updateEmojiState(message);
          },
        ),
      ),
    );
  }
}

class _OriginalMessageBuilder extends ConsumerWidget {
  const _OriginalMessageBuilder({
    required this.message,
  });

  final types.Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.repliedMessage is types.TextMessage) {
      return TextMessageBuilder(
        message: message.repliedMessage as types.TextMessage,
        messageWidth:
            ((message.repliedMessage!.metadata!['messageLength']) * 38.5)
                .toInt(),
      );
    } else if (message.repliedMessage is types.ImageMessage) {
      Uint8List data = base64Decode(
        (message.repliedMessage as types.ImageMessage).metadata?['content'] ??
            '',
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.memory(
          data,
          errorBuilder: (BuildContext context, Object url, StackTrace? error) {
            return Text('Could not load image due to $error');
          },
          frameBuilder: ((context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
              child: child,
            );
          }),
          cacheHeight: 75,
          cacheWidth: 75,
          fit: BoxFit.cover,
        ),
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
