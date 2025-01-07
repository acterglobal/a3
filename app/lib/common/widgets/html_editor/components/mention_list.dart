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
          final avatarInfo = ref.watch(roomAvatarInfoProvider(matchId));
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

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

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
    final menuWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuHeader(),
        const Divider(height: 1, endIndent: 5, indent: 5),
        const SizedBox(height: 8),
        _buildMenuList(suggestions),
      ],
    );

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) => _handleKeyEvent(event, suggestions),
      child: menuWidget,
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
                  isSelected: index == _selectedIndex,
                  onTap: () => _selectItem(mentionId, displayName),
                );
              },
            ),
    );
  }

  KeyEventResult _handleKeyEvent(
    KeyEvent event,
    Map<String, String?> suggestions,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onDismiss();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
        if (suggestions.isNotEmpty) {
          final selectedItem = suggestions.entries.elementAt(_selectedIndex);
          _selectItem(selectedItem.key, selectedItem.value);
        }
        widget.onDismiss();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1).clamp(0, suggestions.length - 1);
        });
        _scrollToSelected();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _selectedIndex =
              (_selectedIndex + 1).clamp(0, suggestions.length - 1);
        });
        _scrollToSelected();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.backspace:
        final selection = widget.editorState.selection;
        if (selection == null) return KeyEventResult.handled;

        final node = widget.editorState.getNodeAtPath(selection.end.path);
        if (node == null) return KeyEventResult.handled;

        // Get text before cursor
        final text = node.delta?.toPlainText() ?? '';
        final cursorPosition = selection.end.offset;
        final mentionTriggers = [userMentionChar, roomMentionChar];

        if (_canDeleteLastCharacter()) {
          // Check if we're about to delete an mention symbol
          if (cursorPosition > 0 &&
              mentionTriggers.contains(text[cursorPosition - 1])) {
            widget.onDismiss(); // Dismiss menu when is deleted
          }
          widget.editorState.deleteBackward();
        } else {
          // Workaround for editor regaining focus
          widget.editorState.apply(
            widget.editorState.transaction..afterSelection = selection,
          );
        }
        return KeyEventResult.handled;

      default:
        if (event.character != null &&
                !HardwareKeyboard.instance.isAltPressed &&
                !HardwareKeyboard.instance.isMetaPressed ||
            !HardwareKeyboard.instance.isShiftPressed) {
          widget.editorState.insertTextAtCurrentSelection(event.character!);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
    }
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

    transaction.replaceText(
      node,
      atSymbolPosition, // Start exactly from trigger
      lengthToReplace, // Replace everything including trigger
      ' ',
      attributes: {
        mentionTypeStr: MentionAttributes(
          type: mentionType,
          mentionId: id,
          displayName: displayName,
        ),
      },
    );

    widget.editorState.apply(transaction);
    widget.onDismiss();
  }

  void _scrollToSelected() {
    const double kItemHeight = 60;
    final itemPosition = _selectedIndex * kItemHeight;
    if (itemPosition < _scrollController.offset) {
      _scrollController.animateTo(
        itemPosition,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else if (itemPosition + kItemHeight >
        _scrollController.offset +
            _scrollController.position.viewportDimension) {
      _scrollController.animateTo(
        itemPosition +
            kItemHeight -
            _scrollController.position.viewportDimension,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  bool _canDeleteLastCharacter() {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return false;
    }

    final node = widget.editorState.getNodeAtPath(selection.start.path);
    if (node?.delta == null) {
      return false;
    }
    return selection.start.offset > 0;
  }
}
