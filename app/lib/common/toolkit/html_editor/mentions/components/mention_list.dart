import 'dart:async';
import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/html_editor/mentions/components/mention_item.dart';
import 'package:acter/common/toolkit/html_editor/mentions/models/mention_type.dart';
import 'package:acter/common/toolkit/html_editor/mentions/selected_mention_provider.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserMentionList extends ConsumerWidget {
  final EditorState editorState;
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final String roomId;
  final MentionSelectedFn onSelected;

  const UserMentionList({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.onShow,
    required this.roomId,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => MentionList(
    roomId: roomId,
    editorState: editorState,
    onDismiss: onDismiss,
    onShow: onShow,
    // the actual provider
    mentionsProvider: filteredUserSuggestionsProvider(roomId),
    selectedIndexProvider: selecteUserMentionProvider(roomId),
    avatarBuilder: (matchId, ref) {
      final avatarInfo = ref.watch(
        memberAvatarInfoProvider((roomId: roomId, userId: matchId)),
      );
      return AvatarOptions.DM(avatarInfo, size: 18);
    },
    // the fields
    headerTitle: L10n.of(context).users,
    notFoundTitle: L10n.of(context).noUserFoundTitle,
    onSelected:
        (id, displayName) => onSelected(MentionType.user, id, displayName),
  );
}

class RoomMentionList extends StatelessWidget {
  final EditorState editorState;
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final String roomId;
  final MentionSelectedFn onSelected;
  const RoomMentionList({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.onShow,
    required this.roomId,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => MentionList(
    roomId: roomId,
    editorState: editorState,
    onDismiss: onDismiss,
    onShow: onShow,
    // the actual provider
    mentionsProvider: filteredRoomSuggestionsProvider(roomId),
    avatarBuilder: (matchId, ref) {
      final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
      return AvatarOptions(avatarInfo, size: 28);
    },
    // the fields
    headerTitle: L10n.of(context).chats,
    notFoundTitle: L10n.of(context).noChatsFound,
    selectedIndexProvider: selectedRoomMentionProvider(roomId),
    onSelected:
        (id, displayName) => onSelected(MentionType.room, id, displayName),
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
    required this.onShow,
    required this.onSelected,
    required this.selectedIndexProvider,
  });

  final String roomId;
  final EditorState editorState;
  final ProviderBase<Map<String, String>?> mentionsProvider;
  final AvatarOptions Function(String matchId, WidgetRef ref) avatarBuilder;
  final String headerTitle;
  final String notFoundTitle;
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final ProviderBase<int?> selectedIndexProvider;
  final Function(String id, String? displayName) onSelected;
  @override
  ConsumerState<MentionList> createState() => MentionHandlerState();
}

class MentionHandlerState extends ConsumerState<MentionList> {
  final _scrollController = ScrollController();
  StreamSubscription<EditorTransactionValue>? _updateListener;

  @override
  void initState() {
    super.initState();
    _updateListener?.cancel();
    _updateListener = widget.editorState.transactionStream.listen((data) {
      // to use dismiss overlay also search list
      final selection = widget.editorState.selection;
      if (selection == null) {
        widget.onDismiss();
        return;
      }

      final node = widget.editorState.getNodeAtPath(selection.end.path);
      if (node == null) {
        widget.onDismiss();
        return;
      }

      final text = node.delta?.toPlainText() ?? '';
      final cursorPosition = selection.end.offset;

      // inject handlers
      _overlayHandler(text, cursorPosition);
      _mentionSearchHandler(text, cursorPosition);
    });
  }

  @override
  void didUpdateWidget(covariant MentionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mentionsProvider != widget.mentionsProvider) {
      ref.read(mentionQueryProvider.notifier).state = null;
    }
  }

  @override
  void dispose() {
    widget.onDismiss();
    _updateListener?.cancel();
    _scrollController.dispose();
    ref.read(mentionQueryProvider.notifier).state = null;
    super.dispose();
  }

  Map<String, String> get filteredSuggestions =>
      ref.watch(widget.mentionsProvider) ?? {};

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Text(widget.headerTitle),
        ),
        _buildMenuList(),
      ],
    );
  }

  Widget _buildMenuList() {
    final theme = Theme.of(context);
    final options = widget.avatarBuilder;
    if (filteredSuggestions.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100, minWidth: 100),
        child: Center(child: Text(widget.notFoundTitle)),
      );
    }
    return Flexible(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        controller: _scrollController,
        itemCount: filteredSuggestions.length,
        separatorBuilder:
            (context, index) => Divider(
              endIndent: 5,
              indent: 5,
              color: theme.dividerTheme.color,
            ),
        itemBuilder: (context, index) {
          final mentionId = filteredSuggestions.keys.elementAt(index);
          final displayName = filteredSuggestions.values.elementAt(index);

          return MentionItem(
            mentionId: mentionId,
            displayName: displayName,
            avatarOptions: options(mentionId, ref),
            selected: index == ref.watch(widget.selectedIndexProvider),
            onTap:
                (String id, {String? displayName}) =>
                    widget.onSelected(id, displayName),
          );
        },
      ),
    );
  }

  void _overlayHandler(String text, int cursorPosition) {
    // basic validation
    if (text.isEmpty || cursorPosition < 0) {
      widget.onDismiss();
      return;
    }

    // ensure within bounds
    final effectiveCursorPos = min(cursorPosition, text.length);
    final searchStartIndex = max(0, effectiveCursorPos - 1);

    // last trigger char before cursor
    int triggerIndex = -1;
    for (int i = searchStartIndex; i >= 0; i--) {
      if (text[i] == userMentionChar || text[i] == roomMentionChar) {
        triggerIndex = i;

        break;
      }
    }

    // no trigger found, dismiss
    if (triggerIndex == -1) {
      widget.onDismiss();
      return;
    }

    //cursor is before or at trigger position, dismiss
    if (effectiveCursorPos <= triggerIndex) {
      widget.onDismiss();
      return;
    }

    final textBetween = text.substring(triggerIndex + 1, effectiveCursorPos);

    if (textBetween.contains(' ')) {
      widget.onDismiss();
    } else {
      // we're in a valid mention context

      widget.onShow();
    }
  }

  void _mentionSearchHandler(String text, int cursorPosition) {
    if (text.isEmpty || cursorPosition <= 0 || cursorPosition > text.length) {
      return;
    }

    final mentionTriggers = [userMentionChar, roomMentionChar];
    String searchQuery = '';

    // ensure search start index is within bounds
    final searchStartIndex = min(cursorPosition - 1, text.length - 1);

    for (int i = searchStartIndex; i >= 0; i--) {
      if (mentionTriggers.contains(text[i])) {
        // Ensure substring bounds are within text length
        final endIndex = min(cursorPosition, text.length);
        searchQuery = text.substring(i + 1, endIndex).trim().toLowerCase();
        break;
      }
    }

    // Update filtered suggestions based on search query
    ref.read(mentionQueryProvider.notifier).state = searchQuery;
  }
}
