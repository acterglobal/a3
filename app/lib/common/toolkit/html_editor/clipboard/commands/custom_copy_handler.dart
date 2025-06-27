import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
  'a3::common::toolkit::html_editor::clipboard::commands::custom_copy_handler',
);

class CustomCopyHandler {
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

    // copy event listener for external clipboard events
    events.registerCopyEventListener((event) async {
      final editorState = _currentEditorState;
      if (editorState == null) return;

      await _handleCopyEvent(editorState, event, isCut: false);
    });

    //  cut event listener for external clipboard events
    events.registerCutEventListener((event) async {
      final editorState = _currentEditorState;
      if (editorState == null) return;

      await _handleCopyEvent(editorState, event, isCut: true);
    });
  }

  static Future<void> _handleCopyEvent(
    EditorState editorState,
    ClipboardWriteEvent event, {
    bool isCut = false,
  }) async {
    final selection = editorState.selection?.normalized;
    if (selection == null || selection.isCollapsed) {
      return;
    }

    try {
      final markdown = editorState.intoMarkdown();

      final item = DataWriterItem();

      item.add(Formats.plainText(markdown));

      await event.write([item]);

      // if is cut, delete the selection also
      if (isCut) {
        await editorState.deleteSelection(selection);
      }
    } catch (e) {
      _log.info('Error handling copy/cut event: $e');
    }
  }

  static void dispose() {
    final events = ClipboardEvents.instance;
    if (events != null) {
      // unregister the copy and cut event listeners
      events.unregisterCutEventListener((_) => _initClipboardEvents);
      events.unregisterCopyEventListener((_) => _initClipboardEvents);
    }
    _currentEditorState = null;
    _isInitialized = false;
  }
}
