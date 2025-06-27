import 'package:acter/common/toolkit/html_editor/services/clipboard_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:super_clipboard/super_clipboard.dart';

/*
 * This file contains code derived from AppFlowy
 * Original source: https://github.com/AppFlowy-IO/AppFlowy
 * Licensed under AGPL-3.0
 * 
 * Modifications made: Enhanced with clipboard event handling
 * Date of derivation: 27 June 2025
 */
final _log = Logger(
  'a3::common::toolkit::html_editor::commands::custom_paste_command',
);

final List<CommandShortcutEvent> customPasteCommands = [customPasteCommand];

final CommandShortcutEvent customPasteCommand = CommandShortcutEvent(
  key: 'paste the content',
  getDescription: () => AppFlowyEditorL10n.current.cmdPasteContent,
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: _customPasteCommandHandler,
);

CommandShortcutEventHandler _customPasteCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  () async {
    final data = await HtmlEditorClipboardService().getFormattedText();
    final richText = data.richText;
    if (richText == null || richText.isEmpty) {
      return false;
    }

    // shared paste logic
    await CustomPasteHandler._handlePasteContent(editorState, richText);
    return true;
  }();

  return KeyEventResult.handled;
};

class CustomPasteHandler {
  static EditorState? _currentEditorState;
  static bool _isInitialized = false;

  static void initialize(EditorState editorState) {
    _currentEditorState = editorState;

    if (!_isInitialized) {
      _initClipboardEvents();
      _isInitialized = true;
    }
  }

  static void _initClipboardEvents() {
    final events = ClipboardEvents.instance;
    if (events == null) {
      // clipboard events are only supported on web
      return;
    }

    events.registerPasteEventListener((event) async {
      final editorState = _currentEditorState;
      if (editorState == null) return;

      final reader = await event.getClipboardReader();

      // try to get html first
      String? content;
      if (reader.canProvide(Formats.htmlText)) {
        content = await reader.readValue(Formats.htmlText);
      } else if (reader.canProvide(Formats.plainText)) {
        content = await reader.readValue(Formats.plainText);
      }

      if (content != null && content.isNotEmpty) {
        await _handlePasteContent(editorState, content);
      }
    });
  }

  static Future<bool> _handlePasteContent(
    EditorState editorState,
    String content,
  ) async {
    final selection = editorState.selection;
    if (selection == null) {
      return false;
    }

    try {
      final nodes = htmlToDocument(content).root.children.toList();

      // Remove empty nodes from front and back
      while (nodes.isNotEmpty &&
          nodes.first.delta?.isEmpty == true &&
          nodes.first.children.isEmpty) {
        nodes.removeAt(0);
      }
      while (nodes.isNotEmpty &&
          nodes.last.delta?.isEmpty == true &&
          nodes.last.children.isEmpty) {
        nodes.removeLast();
      }

      if (nodes.isEmpty) {
        return false;
      }

      if (nodes.length == 1) {
        await editorState.pasteSingleLineNode(nodes.first);
      } else {
        await editorState.pasteMultiLineNodes(nodes.toList());
      }

      return true;
    } catch (e) {
      _log.info('Error pasting content: $e');
      return false;
    }
  }

  static void dispose() {
    final events = ClipboardEvents.instance;
    if (events != null) {
      // unregister the paste event listener
      events.unregisterPasteEventListener((_) => _initClipboardEvents);
    }
    _currentEditorState = null;
    _isInitialized = false;
  }
}
