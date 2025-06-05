import 'package:acter/common/toolkit/html_editor/mentions/mention_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// If the mention menu is open , his reacts to up and forwards that to the MentionMenu controller
final CommandShortcutEvent upCommandForMentions = CommandShortcutEvent(
  key: 'select previous mention',
  getDescription: () => 'select previous mention',
  command: 'arrow up',
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
  key: 'select next mention',
  getDescription: () => 'select next mention',
  command: 'arrow down',
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
      key: 'select current mention',
      getDescription: () => 'select current mention',
      command: 'tab, shift+tab, enter, space, return',
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

/// If the mention menu is open , his reacts to up and forwards that to the MentionMenu controller
final CommandShortcutEvent dismissMentionMenuCommand = CommandShortcutEvent(
  key: 'dismiss mention menu',
  getDescription: () => 'dismiss mention menu',
  command: 'escape',
  handler: _dismissMentionMenuCommandHandler,
);

CommandShortcutEventHandler _dismissMentionMenuCommandHandler = (editorState) {
  if (MentionMenu.isShowing()) {
    MentionMenu.dismiss();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

final mentionMenuCommandShortcutEvents = [
  // upCommandForMentions,
  // downCommandForMentions,
  // selectCurrentCommandForMentions,
  dismissMentionMenuCommand,
];
