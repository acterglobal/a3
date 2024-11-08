import 'package:acter/common/widgets/html_editor/components/mention_item.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/common/widgets/html_editor/models/mention_block_keys.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentionList extends ConsumerStatefulWidget {
  const MentionList({
    super.key,
    required this.editorState,
    required this.roomId,
    required this.mentionType,
    required this.onDismiss,
    required this.onSelectionUpdate,
  });

  final EditorState editorState;
  final String roomId;
  final MentionType mentionType;
  final VoidCallback onDismiss;
  final VoidCallback onSelectionUpdate;

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
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // All suggestions list
    final suggestions = ref
        .watch(mentionSuggestionsProvider((widget.roomId, widget.mentionType)));
    if (suggestions == null) {
      return ErrorWidget(L10n.of(context).loadingFailed);
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKeyEvent(node, event, suggestions),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuHeader(),
          const Divider(height: 1, endIndent: 5, indent: 5),
          const SizedBox(height: 8),
          _buildMenuList(suggestions),
        ],
      ),
    );
  }

  Widget _buildMenuHeader() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          widget.mentionType == MentionType.user
              ? L10n.of(context).foundUsers
              : 'Rooms',
        ),
      );

  Widget _buildMenuList(Map<String, String> suggestions) {
    return Flexible(
      child: suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No results found',
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              controller: _scrollController,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final userId = suggestions.keys.elementAt(index);
                final displayName = suggestions.values.elementAt(index);
                return MentionItem(
                  userId: userId,
                  displayName: displayName,
                  isSelected: index == _selectedIndex,
                  onTap: () => _selectItem(userId, displayName),
                );
              },
            ),
    );
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    Map<String, String> suggestions,
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
        if (_canDeleteLastCharacter()) {
          widget.editorState.deleteBackward();
        } else {
          // Workaround for editor regaining focus
          widget.editorState.apply(
            widget.editorState.transaction
              ..afterSelection = widget.editorState.selection,
          );
        }
        final isEmpty = widget.editorState.selection?.end.offset == 0;

        if (isEmpty) {
          widget.onDismiss();
        }
        return KeyEventResult.handled;

      default:
        if (event.character != null &&
                !HardwareKeyboard.instance.isAltPressed &&
                !HardwareKeyboard.instance.isMetaPressed ||
            !HardwareKeyboard.instance.isShiftPressed) {
          widget.onSelectionUpdate();
          widget.editorState.insertTextAtCurrentSelection(event.character!);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
    }
  }

  void _selectItem(String id, String displayName) {
    final selection = widget.editorState.selection;
    if (selection == null) return;

    final transaction = widget.editorState.transaction;
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    final length = selection.end.offset - (selection.start.offset - 1);

    if (node == null) return;

    transaction.replaceText(
      node,
      selection.start.offset - 1,
      length,
      ' ',
      attributes: {
        MentionBlockKeys.mention: {
          MentionBlockKeys.type: widget.mentionType.name,
          if (widget.mentionType == MentionType.user)
            MentionBlockKeys.userId: id
          else
            MentionBlockKeys.roomId: id,
          MentionBlockKeys.displayName: displayName,
        },
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
