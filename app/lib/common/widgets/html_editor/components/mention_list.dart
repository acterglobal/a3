import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/components/mention_item.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/common/widgets/html_editor/models/mention_attributes.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserMentionList extends ConsumerWidget {
  final EditorState editorState;
  final VoidCallback onDismiss;
  final String roomId;

  const UserMentionList({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.roomId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => MentionList(
        roomId: roomId,
        editorState: editorState,
        onDismiss: onDismiss,
        // the actual provider
        mentionsProvider: userMentionSuggestionsProvider(roomId),
        avatarBuilder: (matchId, ref) {
          final avatarInfo = ref.watch(
            memberAvatarInfoProvider((roomId: roomId, userId: matchId)),
          );
          return AvatarOptions.DM(avatarInfo, size: 18);
        },
        // the fields
        headerTitle: L10n.of(context).users,
        notFoundTitle: L10n.of(context).noUserFoundTitle,
      );
}

class RoomMentionList extends StatelessWidget {
  final EditorState editorState;
  final VoidCallback onDismiss;
  final String roomId;

  const RoomMentionList({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.roomId,
  });
  @override
  Widget build(BuildContext context) => MentionList(
        roomId: roomId,
        editorState: editorState,
        onDismiss: onDismiss,
        // the actual provider
        mentionsProvider: roomMentionsSuggestionsProvider(roomId),
        avatarBuilder: (matchId, ref) {
          final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
          return AvatarOptions(avatarInfo, size: 28);
        },
        // the fields
        headerTitle: L10n.of(context).chats,
        notFoundTitle: L10n.of(context).noChatsFound,
      );
}

class MentionList extends ConsumerStatefulWidget {
  const MentionList({
    super.key,
    required this.roomId,
    required this.editorState,
    required this.mentionsProvider,
    required this.avatarBuilder,
    required this.headerTitle,
    required this.notFoundTitle,
    required this.onDismiss,
  });

  final String roomId;
  final EditorState editorState;
  final ProviderBase<Map<String, String>?> mentionsProvider;
  final AvatarOptions Function(String matchId, WidgetRef ref) avatarBuilder;
  final String headerTitle;
  final String notFoundTitle;
  final VoidCallback onDismiss;

  @override
  ConsumerState<MentionList> createState() => _MentionHandlerState();
}

class _MentionHandlerState extends ConsumerState<MentionList> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    widget.onDismiss();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mentionsProvider = widget.mentionsProvider;
    // All suggestions list
    final suggestions = ref.watch(mentionsProvider);
    if (suggestions == null) {
      return ErrorWidget(L10n.of(context).loadingFailed);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuHeader(),
        const Divider(height: 1, endIndent: 5, indent: 5),
        const SizedBox(height: 8),
        _buildMenuList(suggestions),
      ],
    );
  }

  Widget _buildMenuHeader() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(widget.headerTitle),
      );

  Widget _buildMenuList(Map<String, String?> suggestions) {
    final String notFoundTitle = widget.notFoundTitle;
    final options = widget.avatarBuilder;
    return Flexible(
      child: suggestions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(notFoundTitle),
            )
          : ListView.builder(
              shrinkWrap: true,
              controller: _scrollController,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final mentionId = suggestions.keys.elementAt(index);
                final displayName = suggestions.values.elementAt(index);

                return MentionItem(
                  mentionId: mentionId,
                  displayName: displayName,
                  avatarOptions: options(mentionId, ref),
                  onTap: () => _selectItem(mentionId, displayName),
                );
              },
            ),
    );
  }

  void _selectItem(String id, String? displayName) {
    final selection = widget.editorState.selection;
    if (selection == null) return;

    final transaction = widget.editorState.transaction;
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    if (node == null) return;

    final text = node.delta?.toPlainText() ?? '';
    final cursorPosition = selection.end.offset;

    // Find the trigger symbol position by searching backwards from cursor
    int atSymbolPosition = -1;
    final mentionTriggers = [userMentionChar, roomMentionChar];
    String mentionTypeStr = '';
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (mentionTriggers.contains(text[i])) {
        mentionTypeStr = text[i];
        atSymbolPosition = i;
        break;
      }
    }

    if (atSymbolPosition == -1) return; // No trigger found

    // Calculate length from trigger to cursor
    final lengthToReplace = cursorPosition - atSymbolPosition;
    final mentionType = MentionType.fromStr(mentionTypeStr);
    final uniqueMarker = '‖';

    transaction.replaceText(
      node,
      atSymbolPosition, // Start exactly from trigger
      lengthToReplace, // Replace everything including trigger
      uniqueMarker,
      attributes: {
        mentionTypeStr: MentionAttributes(
          type: mentionType,
          mentionId: id,
          displayName: displayName,
        ),
        'inline': true,
      },
    );

    widget.editorState.apply(transaction);
    widget.onDismiss();
  }
}
