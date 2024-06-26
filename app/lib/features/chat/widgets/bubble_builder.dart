import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/emoji/emoji_container.dart';
import 'package:acter/features/chat/widgets/emoji/emoji_row.dart';
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

    String eventType = message.metadata?['eventType'] ?? '';
    bool isMemberEvent = eventType == 'm.room.member';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        isMemberEvent
            ? child
            : SwipeTo(
                onRightSwipe: (DragUpdateDetails details) {
                  ref
                      .read(chatInputProvider(roomId).notifier)
                      .setReplyToMessage(message);
                },
                iconOnRightSwipe: Icons.reply_rounded,
                onLeftSwipe: isAuthor
                    ? (DragUpdateDetails details) {
                        ref
                            .read(chatInputProvider(roomId).notifier)
                            .setEditMessage(message);
                      }
                    : null,
                iconOnLeftSwipe: Atlas.pencil_edit_thin,
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
    late List<Widget> children;
    if (actionsVisible) {
      children = [
        EmojiRow(
          roomId: roomId,
          isAuthor: isAuthor,
          onEmojiTap: (String eventId, String emoji) {
            ref.read(chatInputProvider(roomId).notifier).unsetSelectedMessage();
            toggleReaction(ref, eventId, emoji);
          },
          message: message,
        ),
        enlargeEmoji ? child : renderBubble(context, isAuthor),
        MessageActions(
          convo: convo,
          roomId: roomId,
        ),
      ];
    } else {
      children = [
        const SizedBox(height: 4),
        enlargeEmoji ? child : renderBubble(context, isAuthor),
        EmojiContainer(
          roomId: roomId,
          onToggle: (eventId, emoji) => toggleReaction(ref, eventId, emoji),
          isAuthor: isAuthor,
          message: message,
          nextMessageInGroup: nextMessageInGroup,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MessageMetadataBuilder(
              convo: convo,
              message: message,
            ),
          ],
        ),
      ];
    }

    return Column(
      crossAxisAlignment:
          isAuthor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: children,
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
                  : Theme.of(context)
                      .colorScheme
                      .secondaryContainer
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
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
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
        ref.watch(memberAvatarInfoProvider((userId: authorId, roomId: roomId)));
    return Row(
      children: [
        ActerAvatar(
          options: AvatarOptions.DM(
            replyProfile,
            size: 12,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          replyProfile.displayName ?? '',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
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
