import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/emoji_reaction_item.dart';
import 'package:acter/features/chat/widgets/emoji_row.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/receipts_builder.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_to/swipe_to.dart';

class BubbleBuilder extends ConsumerWidget {
  final Convo convo;
  final Widget child;
  final types.Message message;
  final bool nextMessageInGroup;
  final bool enlargeEmoji;

  const BubbleBuilder({
    Key? key,
    required this.convo,
    required this.child,
    required this.message,
    required this.nextMessageInGroup,
    required this.enlargeEmoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final isAuthor = (myId == message.author.id);
    final roomId = convo.getRoomIdStr();

    final chatInputState = ref.watch(chatInputProvider(roomId));
    final chatInputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    final chatInputFocusState = ref.watch(chatInputFocusProvider.notifier);

    String eventType = message.metadata?['eventType'] ?? '';
    bool isMemberEvent = eventType == 'm.room.member';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        isMemberEvent
            ? child
            : SwipeTo(
                onLeftSwipe: !isAuthor
                    ? null
                    : () {
                        FocusScope.of(context)
                            .requestFocus(chatInputFocusState.state);
                        if (chatInputState.currentMessageId != null) {
                          chatInputNotifier.emojiRowVisible(false);
                          chatInputNotifier.setRepliedToMessage(message);
                          chatInputNotifier.toggleReplyView(true);
                          chatInputNotifier.setReplyWidget(child);
                        } else {
                          chatInputNotifier.toggleReplyView(true);
                          chatInputNotifier.setRepliedToMessage(message);
                          chatInputNotifier.setReplyWidget(child);
                        }
                      },
                onRightSwipe: isAuthor
                    ? null
                    : () {
                        FocusScope.of(context)
                            .requestFocus(chatInputFocusState.state);
                        if (chatInputState.emojiRowVisible) {
                          chatInputNotifier.emojiRowVisible(false);

                          chatInputNotifier.setRepliedToMessage(message);
                          chatInputNotifier.toggleReplyView(true);
                          chatInputNotifier.setReplyWidget(child);
                        } else {
                          chatInputNotifier.toggleReplyView(true);
                          chatInputNotifier.setRepliedToMessage(message);
                          chatInputNotifier.setReplyWidget(child);
                        }
                      },
                child: _ChatBubble(
                  convo: convo,
                  message: message,
                  nextMessageInGroup: nextMessageInGroup,
                  enlargeEmoji: enlargeEmoji,
                  child: child,
                ),
              ),
      ],
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  final Convo convo;
  final types.Message message;
  final bool nextMessageInGroup;
  final Widget child;
  final bool enlargeEmoji;

  const _ChatBubble({
    required this.convo,
    required this.message,
    required this.nextMessageInGroup,
    required this.child,
    required this.enlargeEmoji,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final isAuthor = (myId == message.author.id);
    final roomId = convo.getRoomIdStr();
    bool hasRepliedMessage = message.repliedMessage != null;
    final receipts = message.metadata?['receipts'];

    return Column(
      crossAxisAlignment:
          isAuthor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        EmojiRow(
          roomId: roomId,
          onEmojiTap: (String eventId, String emoji) {
            final inputNotifier = ref.read(chatInputProvider(roomId).notifier);
            inputNotifier.setCurrentMessageId(null);
            inputNotifier.emojiRowVisible(false);
            sendEmojiReaction(eventId, emoji);
          },
          message: message,
        ),
        const SizedBox(height: 4),
        enlargeEmoji
            ? child
            : Bubble(
                color: isAuthor
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.neutral2,
                borderColor: Colors.transparent,
                style: BubbleStyle(
                  margin: nextMessageInGroup
                      ? const BubbleEdges.symmetric(horizontal: 2)
                      : null,
                  radius: const Radius.circular(22),
                  padding: (message is types.ImageMessage && !hasRepliedMessage)
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
                child: hasRepliedMessage
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: isAuthor
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
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
                                  child: Consumer(builder: replyProfileBuilder),
                                ),
                                _OriginalMessageBuilder(
                                  convo: convo,
                                  message: message,
                                ),
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
            onSendEmoji: sendEmojiReaction,
            isAuthor: isAuthor,
            message: message,
            nextMessageInGroup: nextMessageInGroup,
          ),
        ),
        if (receipts != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ReceiptsBuilder(
                seenList: (receipts as Map<String, int>).keys.toList(),
              ),
            ],
          ),
      ],
    );
  }

  Widget replyProfileBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final authorId = message.repliedMessage!.author.id;
    final replyProfile = ref.watch(memberProfileByIdProvider(authorId));
    return Row(
      children: [
        replyProfile.when(
          data: (profile) => ActerAvatar(
            uniqueId: authorId,
            displayName: profile.displayName,
            mode: DisplayMode.User,
            avatar: profile.getAvatarImage(),
            size: profile.hasAvatar() ? 12 : 24,
          ),
          error: (err, stackTrace) {
            debugPrint('Failed to load profile due to $err');
            return ActerAvatar(
              uniqueId: authorId,
              displayName: authorId,
              mode: DisplayMode.User,
              size: 24,
            );
          },
          loading: () => const CircularProgressIndicator(),
        ),
        const SizedBox(width: 5),
        replyProfile.when(
          data: (profile) => Text(
            profile.displayName ?? '',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          error: (err, stackTrace) {
            debugPrint('Failed to load profile due to $err');
            return const Text('');
          },
          loading: () => const CircularProgressIndicator(),
        ),
      ],
    );
  }

  // send emoji reaction to message event
  Future<void> sendEmojiReaction(String eventId, String emoji) async {
    try {
      await convo.sendReaction(eventId, emoji);
    } catch (e) {
      debugPrint('$e');
    }
  }
}

class _EmojiContainer extends ConsumerStatefulWidget {
  final Function(String messageId, String emoji) onSendEmoji;
  final bool isAuthor;
  final types.Message message;
  final bool nextMessageInGroup;

  const _EmojiContainer({
    required this.onSendEmoji,
    required this.isAuthor,
    required this.message,
    required this.nextMessageInGroup,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __EmojiContainerState();
}

class __EmojiContainerState extends ConsumerState<_EmojiContainer>
    with TickerProviderStateMixin {
  late TabController tabBarController;
  List<Tab> reactionTabs = [];

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(
      length: reactionTabs.length,
      vsync: this,
    );
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Wrap(
            direction: Axis.horizontal,
            spacing: 5,
            runSpacing: 3,
            children: List.generate(keys.length, (int index) {
              String key = keys[index];
              Map<String, dynamic> reactions =
                  widget.message.metadata!['reactions'];
              final recordsCount = reactions[key]?.length;
              var sentByMe = (reactions[key]! as List<ReactionRecord>)
                  .any((x) => x.sentByMe());
              return InkWell(
                onLongPress: () {
                  showEmojiReactionsSheet(reactions);
                },
                onTap: () {
                  if (sentByMe) {
                    customMsgSnackbar(
                      context,
                      'Revoking emoji reactions not yet supported',
                    );
                  } else {
                    widget.onSendEmoji(widget.message.id, key);
                  }
                },
                child: Chip(
                  padding: const EdgeInsets.symmetric(
                    vertical: 1,
                    horizontal: 2,
                  ),
                  backgroundColor: sentByMe
                      ? AppTheme.theme.colorScheme.inversePrimary
                      : Colors.transparent,
                  labelPadding: const EdgeInsets.only(left: 2, right: 1),
                  avatar: Text(
                    key,
                    style: EmojiConfig.emojiTextStyle,
                  ),
                  label: Text(recordsCount!.toString()),
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
    Map<String, List<String>> reactionsByUsers = {};
    Map<String, List<String>> usersByReaction = {};
    reactions.forEach((key, value) {
      usersByReaction.putIfAbsent(
        key,
        () => List<String>.empty(growable: true),
      );
      for (final reaction in value) {
        final userId = reaction.senderId().toString();
        reactionsByUsers.putIfAbsent(
          userId,
          () => List<String>.empty(growable: true),
        );
        usersByReaction[key]!.add(userId);
        reactionsByUsers[userId]!.add(key);
      }
    });
    // sort the users per item on the number of emojis sent - highest first
    usersByReaction.forEach((key, users) {
      users.sort(
        (userIdA, userIdB) => reactionsByUsers[userIdB]!
            .length
            .compareTo(reactionsByUsers[userIdA]!.length),
      );
    });
    final allUsers = reactionsByUsers.keys.toList();
    allUsers.sort(
      (userIdA, userIdB) => reactionsByUsers[userIdB]!
          .length
          .compareTo(reactionsByUsers[userIdA]!.length),
    );

    num total = 0;
    if (mounted) {
      setState(() {
        reactions.forEach((key, value) {
          total += value.length;
          reactionTabs.add(
            Tab(
              child: Chip(
                avatar: Text(key, style: EmojiConfig.emojiTextStyle),
                label: Text('${value.length}'),
              ),
            ),
          );
        });
        reactionTabs.insert(
          0,
          Tab(
            child: Chip(
              label: Text('All $total'),
            ),
          ),
        );
        tabBarController = TabController(
          length: reactionTabs.length,
          vsync: this,
        );
      });
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15),
        ),
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
                    _ReactionListing(
                      users: allUsers,
                      usersMap: reactionsByUsers,
                    ),
                    for (var key in keys)
                      _ReactionListing(
                        users: usersByReaction[key]!,
                        usersMap: reactionsByUsers,
                      ),
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

class _OriginalMessageBuilder extends ConsumerWidget {
  final types.Message message;
  final Convo convo;

  const _OriginalMessageBuilder({
    required this.convo,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.repliedMessage is types.TextMessage) {
      final w = message.repliedMessage!.metadata!['messageLength'] * 38.5;
      return TextMessageBuilder(
        convo: convo,
        message: message.repliedMessage as types.TextMessage,
        messageWidth: w.toInt(),
        isReply: true,
      );
    } else if (message.repliedMessage is types.ImageMessage) {
      final imageMsg = message.repliedMessage as types.ImageMessage;
      return Row(
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 50),
            margin: const EdgeInsets.all(12),
            child: ImageMessageBuilder(
              convo: convo,
              message: imageMsg,
              messageWidth: imageMsg.size.toInt(),
              isReplyContent: true,
            ),
          ),
          Text(
            'sent an image.',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      );
    } else if (message.repliedMessage is types.FileMessage) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message.repliedMessage!.metadata?['content'],
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } else if (message.repliedMessage is types.CustomMessage) {
      return CustomMessageBuilder(
        message: message.repliedMessage as types.CustomMessage,
        messageWidth: 100,
      );
    } else {
      return const SizedBox();
    }
  }
}

class _ReactionListing extends StatelessWidget {
  final List<String> users;
  final Map<String, List<String>> usersMap; // UserId -> List of Emoji

  const _ReactionListing({
    required this.users,
    required this.usersMap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        return EmojiReactionItem(
          userId: users[index],
          emojis: usersMap[users[index]]!,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
    );
  }
}
