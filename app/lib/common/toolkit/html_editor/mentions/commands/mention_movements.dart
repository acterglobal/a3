import 'package:acter/common/toolkit/html_editor/mentions/components/mention_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// If the mention menu is open , his reacts to up and forwards that to the MentionMenu controller
final CommandShortcutEvent upCommandForMentions = CommandShortcutEvent(
  key: 'up',
  getDescription: () => AppFlowyEditorL10n.current.cmdDeleteLeft,
  command: 'up, shift+up',
  handler: _upCommandHandlerForMentions,
);

CommandShortcutEventHandler _upCommandHandlerForMentions = (editorState) {
  if (MentionMenu.isShowing()) {
    MentionMenu.prev();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

/// If the mention menu is open , his reacts to up and forwards that to the MentionMenu controller
final CommandShortcutEvent downCommandForMentions = CommandShortcutEvent(
  key: 'down',
  getDescription: () => AppFlowyEditorL10n.current.cmdDeleteLeft,
  command: 'down, shift+down',
  handler: _downCommandHandlerForMentions,
);

CommandShortcutEventHandler _downCommandHandlerForMentions = (editorState) {
  if (MentionMenu.isShowing()) {
    MentionMenu.next();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

/// If the mention menu is open , his reacts to up and forwards that to the MentionMenu controller
final CommandShortcutEvent selectCurrentCommandForMentions =
    CommandShortcutEvent(
      key: 'tab',
      getDescription: () => AppFlowyEditorL10n.current.cmdDeleteLeft,
      command: 'tab, shift+tab',
      handler: _selectCurrentCommandHandlerForMentions,
    );

CommandShortcutEventHandler _selectCurrentCommandHandlerForMentions = (
  editorState,
) {
  if (MentionMenu.isShowing()) {
    MentionMenu.selectCurrent();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};
