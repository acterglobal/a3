import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_acter_plugins/appflowy_acter_plugins.dart';
import 'package:string_validator/string_validator.dart';

/// try to convert the pasted url to a link preview block, only works
///   if the selected block is a paragraph block and the url is valid
///
/// - support
///   - desktop
///   - mobile
///   - web
///
final CommandShortcutEvent convertUrlToLinkPreviewBlockCommand =
    CommandShortcutEvent(
  key: 'convert url to link preview block',
  getDescription: () => 'Convert the pasted url to a link preview block',
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: _convertUrlToLinkPreviewBlockCommandHandler,
);

KeyEventResult _convertUrlToLinkPreviewBlockCommandHandler(
  EditorState editorState,
) {
  final selection = editorState.selection;
  if (selection == null ||
      !selection.isCollapsed ||
      selection.startIndex != 0) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null || node.type != ParagraphBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  () async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final url = data?.text;
    if (url == null || !isURL(url)) {
      return pasteCommand.execute(editorState);
    }

    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      linkPreviewNode(url: url),
    );
    await editorState.apply(transaction);
  }();

  return KeyEventResult.handled;
}

/// Try to convert pasted content into link preview, if it fails then we
/// fallback to the standard [pasteCommand].
///
final CommandShortcutEvent linkPreviewCustomPasteCommand = CommandShortcutEvent(
  key: 'paste content w/ link preview converter',
  getDescription: () => 'Paste content with link preview converter',
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: _pasteCommandHandler,
);

CommandShortcutEventHandler _pasteCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  () async {
    final data = await AppFlowyClipboard.getData();
    final text = data.text;

    final result = await _pasteAsLinkPreview(editorState, text);
    if (result) {
      return KeyEventResult.handled;
    }

    return pasteCommand.execute(editorState);
  }();

  return KeyEventResult.handled;
};

Future<bool> _pasteAsLinkPreview(
  EditorState editorState,
  String? text,
) async {
  if (text == null || !isURL(text)) {
    return false;
  }

  final selection = editorState.selection;
  if (selection == null ||
      !selection.isCollapsed ||
      selection.startIndex != 0) {
    return false;
  }

  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null ||
      node.type != ParagraphBlockKeys.type ||
      node.delta?.toPlainText().isNotEmpty == true) {
    return false;
  }

  final transaction = editorState.transaction;
  transaction.insertNode(
    selection.start.path,
    linkPreviewNode(url: text),
  );
  await editorState.apply(transaction);

  return true;
}
