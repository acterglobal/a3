import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:intl/intl.dart';

class ChatEditorActionsPreview extends ConsumerWidget {
  static const closePreviewKey = Key('chat-editor-actions-close');

  final EditorState textEditorState;
  final TimelineEventItem msgItem;
  final String roomId;

  const ChatEditorActionsPreview({
    super.key,
    required this.textEditorState,
    required this.msgItem,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatEditorState = ref.watch(chatEditorStateProvider);
    final memberAvatar = ref.watch(
      memberAvatarInfoProvider((userId: msgItem.sender(), roomId: roomId)),
    );
    final children = <Widget>[];
    if (chatEditorState.isReplying) {
      children.add(
        _buildPreviewView(
          context,
          ref,
          replyPreviewItems(context, memberAvatar),
        ),
      );
      children.add(_buildRepliedToItem(context, msgItem));
    } else if (chatEditorState.isEditing) {
      children.add(
        _buildPreviewView(context, ref, editPreviewItems(context, ref)),
      );
      // add a bit space for clean UI
      children.add(const SizedBox(height: 12));
    }
    return _buildPreviewContainer(context, children);
  }

  Widget _buildPreviewContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6.0),
          topRight: Radius.circular(6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildPreviewView(
    BuildContext context,
    WidgetRef ref,
    List<Widget> previewItems,
  ) {
    return Row(
      children: [
        const SizedBox(width: 1),
        ...previewItems,
        GestureDetector(
          key: closePreviewKey,
          onTap: () async {
            final notifier = ref.read(chatEditorStateProvider.notifier);
            final isEdit = ref.read(chatEditorStateProvider).isEditing;
            if (isEdit) {
              textEditorState.clear();
            }
            notifier.unsetActions();
            // clear the text, but we still keep selection
            final t = textEditorState.transaction;
            final docChildren = textEditorState.document.root.children;
            t.afterSelection = Selection.single(
              path: docChildren.last.path,
              startOffset: docChildren.last.delta?.length ?? 0,
            );
            textEditorState.apply(t);
          },
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  List<Widget> replyPreviewItems(
    BuildContext context,
    AvatarInfo memberAvatar,
  ) => [
    const SizedBox(width: 1),
    const Icon(Icons.reply_rounded, size: 12, color: Colors.grey),
    const SizedBox(width: 4),
    ActerAvatar(options: AvatarOptions.DM(memberAvatar, size: 12)),
    const SizedBox(width: 5),
    Text(
      L10n.of(context).replyTo(toBeginningOfSentenceCase(msgItem.sender())),
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    ),
    const Spacer(),
  ];

  List<Widget> editPreviewItems(BuildContext context, WidgetRef ref) => [
    const SizedBox(width: 1),
    const Icon(Atlas.pencil_edit_thin, size: 12, color: Colors.grey),
    const SizedBox(width: 4),
    Text(
      L10n.of(context).editMessage,
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    ),
    const Spacer(),
  ];

  Widget _buildRepliedToItem(BuildContext context, TimelineEventItem item) {
    final messageId = item.eventId();
    final msgType = item.msgType();
    final content = item.msgContent();
    if (msgType == null || content == null || messageId == null) {
      return const SizedBox.shrink();
    }

    Widget child = switch (msgType) {
      'm.emote' ||
      'm.notice' ||
      'm.server_notice' ||
      'm.text' => TextMessageEvent(content: content, roomId: roomId),
      'm.image' => ImageMessageEvent(
        messageId: messageId,
        roomId: roomId,
        content: content,
      ),
      'm.video' => VideoMessageEvent(
        roomId: roomId,
        messageId: messageId,
        content: content,
      ),
      'm.file' => FileMessageEvent(
        roomId: roomId,
        messageId: messageId,
        content: content,
      ),
      _ => const SizedBox.shrink(),
    };

    // keep this UI logic for clipping reply content
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 100),
      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: OverflowBox(
            fit: OverflowBoxFit.deferToChild,
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            minHeight: 0,
            child: child,
          ),
        ),
      ),
    );
  }
}
