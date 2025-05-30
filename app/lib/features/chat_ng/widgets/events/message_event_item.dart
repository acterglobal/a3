import 'dart:io';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/chat_ng/dialogs/message_actions.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/chat_ng/widgets/replied_to_preview.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_to/swipe_to.dart';

class MessageEventItem extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final TimelineEventItem item;
  final bool isMe;
  final bool isDM;
  final bool canRedact;
  final bool isFirstMessageBySender;
  final bool isLastMessageBySender;
  final bool isLastMessage;

  const MessageEventItem({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
    required this.isMe,
    required this.isDM,
    required this.canRedact,
    required this.isFirstMessageBySender,
    required this.isLastMessageBySender,
    required this.isLastMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendingState = item.sendState();
    return SwipeTo(
      swipeSensitivity: Platform.isIOS ? 30 : 5,
      key: Key(messageId), // needed or swipe doesn't work reliably in listview
      onRightSwipe: (_) => _handleReplySwipe(ref, item),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMessageUI(context, ref, roomId, messageId, item, isMe),
          if (sendingState != null || (isMe && isLastMessage))
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child:
                    sendingState != null
                        ? SendingStateWidget(
                          state: sendingState,
                          showSentIconOnUnknown: isMe && isLastMessage,
                        )
                        : SendingStateWidget.sent(),
              ),
            ),
        ],
      ),
    );
  }

  void _handleReplySwipe(WidgetRef ref, TimelineEventItem item) {
    ref.read(chatEditorStateProvider.notifier).setReplyToMessage(item);
  }

  Widget _buildMessageUI(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String messageId,
    TimelineEventItem item,
    bool isMe,
  ) {
    final messageWidget = buildMsgEventItem(
      context,
      ref,
      roomId,
      messageId,
      item,
    );

    return GestureDetector(
      onLongPressStart:
          (_) => messageActions(
            context: context,
            messageWidget: messageWidget,
            isMe: isMe,
            canRedact: canRedact,
            item: item,
            messageId: messageId,
            roomId: roomId,
          ),
      child: Hero(tag: messageId, child: messageWidget),
    );
  }

  Widget buildMsgEventItem(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String messageId,
    TimelineEventItem item,
  ) {
    final msgType = item.msgType();
    final content = item.msgContent();
    final wasEdited = item.wasEdited();
    final timestamp = item.originServerTs();
    // shouldn't happen but in case return empty
    if (msgType == null || content == null) return const SizedBox.shrink();

    String? displayName;
    if (isFirstMessageBySender && !isMe && !isDM) {
      final senderId = item.sender();
      final letRoomId = roomId;
      displayName =
          ref
              .watch(
                memberDisplayNameProvider((
                  userId: senderId,
                  roomId: letRoomId,
                )),
              )
              .valueOrNull ??
          senderId;
    }

    return switch (msgType) {
      'm.emote' ||
      'm.notice' ||
      'm.server_notice' ||
      'm.text' => buildTextMsgEvent(context, ref, item, timestamp, displayName),
      'm.image' => _buildMediaMsgEventContainer(
        context,
        ImageMessageEvent(
          messageId: messageId,
          roomId: roomId,
          content: content,
          timestamp: timestamp,
        ),
        isMe,
        isFirstMessageBySender,
        isLastMessageBySender,
        wasEdited,
        displayName,
      ),
      'm.video' => _buildMediaMsgEventContainer(
        context,
        VideoMessageEvent(
          messageId: messageId,
          roomId: roomId,
          content: content,
          timestamp: timestamp,
        ),
        isMe,
        isFirstMessageBySender,
        isLastMessageBySender,
        wasEdited,
        displayName,
      ),
      'm.file' => _buildMediaMsgEventContainer(
        context,
        FileMessageEvent(
          messageId: messageId,
          roomId: roomId,
          content: content,
          timestamp: timestamp,
        ),
        isMe,
        isFirstMessageBySender,
        isLastMessageBySender,
        wasEdited,
        displayName,
      ),
      _ =>
        isNightly || isDevBuild
            ? StateEventContainerWidget(
              child: _buildUnsupportedMessage(context, msgType),
            )
            : const SizedBox.shrink(),
    };
  }

  Widget buildTextMsgEvent(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
    int timestamp,
    String? displayName,
  ) {
    final msgType = item.msgType();
    final repliedToId = item.inReplyToId();
    final wasEdited = item.wasEdited();
    final content = item.msgContent().expect('cannot be null');
    final isNotice = (msgType == 'm.notice' || msgType == 'm.server_notice');

    // whether it contains `replied to` event.
    final repliedToBuilder =
        (repliedToId != null)
            ? RepliedToPreview(roomId: roomId, messageId: messageId, isMe: isMe)
            : null;

    final child = TextMessageEvent(
      content: content,
      roomId: roomId,
      repliedTo: repliedToBuilder,
      isNotice: isNotice,
    );

    if (isMe) {
      return ChatBubble.me(
        context: context,
        isFirstMessageBySender: isFirstMessageBySender,
        isLastMessageBySender: isLastMessageBySender,
        isEdited: wasEdited,
        timestamp: timestamp,
        displayName: displayName,
        child: child,
      );
    }
    return ChatBubble(
      context: context,
      isFirstMessageBySender: isFirstMessageBySender,
      isLastMessageBySender: isLastMessageBySender,
      isEdited: wasEdited,
      timestamp: timestamp,
      displayName: displayName,
      child: child,
    );
  }

  Widget _buildMediaMsgEventContainer(
    BuildContext context,
    Widget mediaMessageWidget,
    bool isMe,
    bool isFirstMessageBySender,
    bool isLastMessageBySender,
    bool wasEdited,
    String? displayName,
  ) {
    return isMe
        ? ChatBubble.me(
          context: context,
          isFirstMessageBySender: isFirstMessageBySender,
          isLastMessageBySender: isLastMessageBySender,
          isEdited: wasEdited,
          displayName: displayName,
          child: mediaMessageWidget,
        )
        : ChatBubble(
          context: context,
          isFirstMessageBySender: isFirstMessageBySender,
          isLastMessageBySender: isLastMessageBySender,
          isEdited: wasEdited,
          displayName: displayName,
          child: mediaMessageWidget,
        );
  }

  Widget _buildUnsupportedMessage(BuildContext context, String msgtype) {
    return Text(L10n.of(context).unsupportedChatMessageType(msgtype));
  }
}
