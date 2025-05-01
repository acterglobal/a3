import 'dart:async';
import 'dart:math' as math;

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/components/mention_item.dart';
import 'package:acter/common/widgets/html_editor/services/constants.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/common/widgets/html_editor/models/mention_attributes.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserMentionList extends ConsumerWidget {
  final EditorState editorState;
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final String roomId;

  const UserMentionList({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.onShow,
    required this.roomId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => MentionList(
    roomId: roomId,
    editorState: editorState,
    onDismiss: onDismiss,
    onShow: onShow,
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
  final VoidCallback onShow;
  final String roomId;

  const RoomMentionList({
    super.key,
    required this.editorState,
    required this.onDismiss,
    required this.onShow,
    required this.roomId,
  });
  @override
  Widget build(BuildContext context) => MentionList(
    roomId: roomId,
    editorState: editorState,
    onDismiss: onDismiss,
    onShow: onShow,
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
    required this.onShow,
  });

  final String roomId;
  final EditorState editorState;
  final ProviderBase<Map<String, String>?> mentionsProvider;
  final AvatarOptions Function(String matchId, WidgetRef ref) avatarBuilder;
  final String headerTitle;
  final String notFoundTitle;
  final VoidCallback onDismiss;
  final VoidCallback onShow;

  @override
  ConsumerState<MentionList> createState() => _MentionHandlerState();
}

class _MentionHandlerState extends ConsumerState<MentionList> {
  final _scrollController = ScrollController();
  StreamSubscription<EditorTransactionValue>? _updateListener;
  Map<String, String>? _filteredSuggestions;

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
  void dispose() {
    widget.onDismiss();
    _updateListener?.cancel();
    _scrollController.dispose();
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
    final displaySuggestions = _filteredSuggestions ?? suggestions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Text(widget.headerTitle),
        ),
        _buildMenuList(displaySuggestions),
      ],
    );
  }

  Widget _buildMenuList(Map<String, String?> suggestions) {
    final theme = Theme.of(context);
    final String notFoundTitle = widget.notFoundTitle;
    final options = widget.avatarBuilder;
    return Flexible(
      child:
          suggestions.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(notFoundTitle),
              )
              : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                controller: _scrollController,
                itemCount: suggestions.length,
                separatorBuilder:
                    (context, index) => Divider(
                      endIndent: 5,
                      indent: 5,
                      color: theme.dividerTheme.color,
                    ),
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

  void _overlayHandler(String text, int cursorPosition) {
    // basic validation
    if (text.isEmpty || cursorPosition < 0) {
      widget.onDismiss();
      return;
    }

    // ensure within bounds
    final effectiveCursorPos = math.min(cursorPosition, text.length);
    final searchStartIndex = math.max(0, effectiveCursorPos - 1);

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
    final searchStartIndex = math.min(cursorPosition - 1, text.length - 1);

    for (int i = searchStartIndex; i >= 0; i--) {
      if (mentionTriggers.contains(text[i])) {
        // Ensure substring bounds are within text length
        final endIndex = math.min(cursorPosition, text.length);
        searchQuery = text.substring(i + 1, endIndex).trim().toLowerCase();
        break;
      }
    }

    // Update filtered suggestions based on search query
    _updateFilteredSuggestions(searchQuery);
  }

  void _updateFilteredSuggestions(String query) {
    final allSuggestions = ref.read(widget.mentionsProvider);
    if (allSuggestions == null) return;

    if (query.isEmpty) {
      setState(() => _filteredSuggestions = allSuggestions);
      return;
    }

    // Filter suggestions based on query
    final filtered = Map.fromEntries(
      allSuggestions.entries.where((entry) {
        final displayName = entry.value.toLowerCase();
        final id = entry.key.toLowerCase();
        return displayName.contains(query) || id.contains(query);
      }),
    );

    setState(() => _filteredSuggestions = filtered);
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
