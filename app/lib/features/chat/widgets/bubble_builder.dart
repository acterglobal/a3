import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/emoji_reaction_item.dart';
import 'package:acter/features/chat/widgets/emoji_row.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/message_actions.dart';
import 'package:acter/features/chat/widgets/message_metadata_builder.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:swipe_to/swipe_to.dart';

final _log = Logger('a3::chat::bubble_builder');

class BubbleBuilder extends ConsumerWidget {
  final Convo convo;
  final Widget child;
  final types.Message message;
  final bool nextMessageInGroup;
  final bool enlargeEmoji;

  const BubbleBuilder({
    super.key,
    required this.convo,
    required this.child,
    required this.message,
    required this.nextMessageInGroup,
    required this.enlargeEmoji,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final isAuthor = (myId == message.author.id);
    final roomId = convo.getRoomIdStr();

    final chatInputNotifier = ref.watch(chatInputProvider(roomId).notifier);

    String eventType = message.metadata?['eventType'] ?? '';
    bool isMemberEvent = eventType == 'm.room.member';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        isMemberEvent
            ? child
            : SwipeTo(
                onLeftSwipe: (DragUpdateDetails details) {
                  chatInputNotifier.setReplyToMessage(message);
                },
                iconOnLeftSwipe: Icons.reply_rounded,
                onRightSwipe: isAuthor
                    ? (DragUpdateDetails details) {
                        chatInputNotifier.setEditMessage(message);
                      }
                    : null,
                iconOnRightSwipe: Atlas.pencil_edit_thin,
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
    final actionsVisible = ref.watch(
      chatInputProvider(roomId).select(
        (state) => // only when showing actions and this is the selected message
            state.selectedMessageState == SelectedMessageState.actions &&
            state.selectedMessage?.id == message.id,
      ),
    );

    return Column(
      crossAxisAlignment:
          isAuthor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (actionsVisible)
          EmojiRow(
            roomId: roomId,
            onEmojiTap: (String eventId, String emoji) {
              ref
                  .read(chatInputProvider(roomId).notifier)
                  .unsetSelectedMessage();
              toggleReaction(ref, eventId, emoji);
            },
            message: message,
          ),
        if (!actionsVisible) const SizedBox(height: 4),
        enlargeEmoji ? child : renderBubble(context, isAuthor),
        if (!actionsVisible)
          _EmojiContainer(
            roomId: roomId,
            onToggle: (eventId, emoji) => toggleReaction(ref, eventId, emoji),
            isAuthor: isAuthor,
            message: message,
            nextMessageInGroup: nextMessageInGroup,
          ),
        if (!actionsVisible)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MessageMetadataBuilder(
                convo: convo,
                message: message,
              ),
            ],
          ),
        if (actionsVisible)
          MessageActions(
            convo: convo,
            roomId: roomId,
          ),
      ],
    );
  }

  Bubble renderBubble(
    BuildContext context,
    bool isAuthor,
  ) {
    bool hasRepliedMessage = message.repliedMessage != null;
    Widget bubbleChild = child;
    if (hasRepliedMessage) {
      bubbleChild = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: isAuthor
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.neutral.withOpacity(0.3),
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
                  child: Consumer(
                    builder: (ctx, ref, child) => replyProfileBuilder(
                      context,
                      ref,
                    ),
                  ),
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
      );
    }

    return Bubble(
      color: isAuthor
          ? Theme.of(context).colorScheme.surface
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
      child: bubbleChild,
    );
  }

  Widget replyProfileBuilder(
    BuildContext context,
    WidgetRef ref,
  ) {
    final roomId = convo.getRoomIdStr();
    final authorId = message.repliedMessage!.author.id;
    final replyProfile =
        ref.watch(roomMemberProvider((userId: authorId, roomId: roomId)));
    return Row(
      children: [
        replyProfile.when(
          data: (data) => ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: authorId,
              displayName: data.profile.displayName,
              avatar: data.profile.getAvatarImage(),
            ),
            size: 12,
          ),
          error: (err, stackTrace) {
            _log.severe('Failed to load profile', err, stackTrace);
            return ActerAvatar(
              mode: DisplayMode.DM,
              avatarInfo: AvatarInfo(uniqueId: authorId),
              size: 24,
            );
          },
          loading: () => Skeletonizer(
            child: ActerAvatar(
              mode: DisplayMode.DM,
              avatarInfo: AvatarInfo(uniqueId: authorId),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 5),
        replyProfile.when(
          data: (data) => Text(
            data.profile.displayName ?? '',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          error: (err, stackTrace) {
            _log.severe('Failed to load profile', err, stackTrace);
            return const Text('');
          },
          loading: () => Skeletonizer(child: Text(authorId)),
        ),
      ],
    );
  }

  // send emoji reaction to message event
  Future<void> toggleReaction(
    WidgetRef ref,
    String eventId,
    String emoji,
  ) async {
    try {
      final stream = ref.read(timelineStreamProvider(convo));
      await stream.toggleReaction(eventId, emoji);
    } catch (e, s) {
      _log.severe('Reaction toggle failed', e, s);
    }
  }
}

class _EmojiContainer extends ConsumerStatefulWidget {
  final String roomId;
  final Function(String messageId, String emoji) onToggle;
  final bool isAuthor;
  final types.Message message;
  final bool nextMessageInGroup;

  const _EmojiContainer({
    required this.roomId,
    required this.onToggle,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        Map<String, dynamic> reactions = {};
        List<String> keys = [];
        final metadata = widget.message.metadata;
        if (metadata == null || !metadata.containsKey('reactions')) {
          return const SizedBox();
        }
        reactions = metadata['reactions'];
        keys = reactions.keys.toList();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Wrap(
            direction: Axis.horizontal,
            spacing: 5,
            runSpacing: 3,
            children: List.generate(keys.length, (int index) {
              String key = keys[index];
              final records = reactions[key]! as List<ReactionRecord>;
              final sentByMe = records.any((x) => x.sentByMe());
              return InkWell(
                onLongPress: () {
                  showEmojiReactionsSheet(reactions, widget.roomId);
                },
                onTap: () {
                  widget.onToggle(widget.message.id, key);
                },
                child: Chip(
                  padding: const EdgeInsets.symmetric(
                    vertical: 1,
                    horizontal: 2,
                  ),
                  backgroundColor: sentByMe
                      ? Theme.of(context).colorScheme.inversePrimary
                      : Colors.transparent,
                  labelPadding: const EdgeInsets.only(left: 2, right: 1),
                  avatar: Text(key, style: EmojiConfig.emojiTextStyle),
                  label: Text(records.length.toString()),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  //Emoji reaction info bottom sheet.
  void showEmojiReactionsSheet(Map<String, dynamic> reactions, String roomId) {
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
              label: Text('${L10n.of(context).all} $total'),
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
                      roomId: roomId,
                      users: allUsers,
                      usersMap: reactionsByUsers,
                    ),
                    for (var key in keys)
                      _ReactionListing(
                        roomId: roomId,
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
    final repliedMessage = message.repliedMessage;
    if (repliedMessage == null) return const SizedBox();
    if (repliedMessage is types.TextMessage) {
      final w = repliedMessage.metadata!['messageLength'] * 38.5;
      return TextMessageBuilder(
        convo: convo,
        message: message.repliedMessage as types.TextMessage,
        messageWidth: w.toInt(),
        isReply: true,
      );
    }
    if (repliedMessage is types.ImageMessage) {
      return Row(
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 50),
            margin: const EdgeInsets.all(12),
            child: ImageMessageBuilder(
              roomId: convo.getRoomIdStr(),
              message: repliedMessage,
              messageWidth: repliedMessage.size.toInt(),
              isReplyContent: true,
            ),
          ),
          Text(
            L10n.of(context).sentAnImage,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      );
    }
    if (repliedMessage is types.FileMessage) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          repliedMessage.metadata!['content'],
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    if (repliedMessage is types.CustomMessage) {
      return CustomMessageBuilder(
        message: repliedMessage,
        messageWidth: 100,
      );
    }
    return const SizedBox();
  }
}

class _ReactionListing extends StatelessWidget {
  final String roomId;
  final List<String> users;
  final Map<String, List<String>> usersMap; // UserId -> List of Emoji

  const _ReactionListing({
    required this.roomId,
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
          roomId: roomId,
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
