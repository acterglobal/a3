import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:intl/intl.dart';

class ChatEditorActionsPreview extends ConsumerStatefulWidget {
  final EditorState textEditorState;
  final RoomEventItem msgItem;
  final String roomId;
  const ChatEditorActionsPreview({
    super.key,
    required this.textEditorState,
    required this.msgItem,
    required this.roomId,
  });

  @override
  ConsumerState<ChatEditorActionsPreview> createState() =>
      _ChatEditorActionsPreviewConsumerState();
}

class _ChatEditorActionsPreviewConsumerState
    extends ConsumerState<ChatEditorActionsPreview> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatEditorState = ref.read(chatEditorStateProvider);
    final textEditorState = widget.textEditorState;
    final msgItem = widget.msgItem;

    if (chatEditorState.isEditing) {
      final transaction = textEditorState.transaction;
      final msgContent = msgItem.msgContent();
      if (msgContent == null) return;
      final doc = ActerDocumentHelpers.fromMsgContent(msgContent);
      Node rootNode = doc.root;
      transaction.document.insert([0], rootNode.children);
      transaction.afterSelection =
          Selection.single(path: rootNode.path, startOffset: 0);
      textEditorState.apply(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatEditorState = ref.watch(chatEditorStateProvider);
    final children = <Widget>[];
    if (chatEditorState.isReplying) {
      children.add(_buildRepliedToMsgView());
      if (chatEditorState.selectedMessage != null) {
        children.add(chatEditorState.selectedMessage!);
      }
    } else if (chatEditorState.isEditing) {
      children.add(_buildEditView());
      // add a bit space for clean UI
      children.add(const SizedBox(height: 12));
    }
    return _buildPreviewContainer(children);
  }

  Widget _buildPreviewContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6.0),
          topRight: Radius.circular(6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 12.0,
          left: 16.0,
          right: 16.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildRepliedToMsgView() {
    final authorId = widget.msgItem.sender();
    final memberAvatar = ref.watch(
      memberAvatarInfoProvider((userId: authorId, roomId: widget.roomId)),
    );
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(
          Icons.reply_rounded,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        ActerAvatar(
          options: AvatarOptions.DM(
            memberAvatar,
            size: 12,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          L10n.of(context).replyTo(toBeginningOfSentenceCase(authorId)),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () =>
              ref.read(chatEditorStateProvider.notifier).unsetActions(),
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  Widget _buildEditView() {
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(
          Atlas.pencil_edit_thin,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          L10n.of(context).editMessage,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () =>
              ref.read(chatEditorStateProvider.notifier).unsetActions(),
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }
}
