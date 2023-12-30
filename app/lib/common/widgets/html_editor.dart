import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/plugins/html/html_document_decoder.dart';
import 'package:appflowy_editor/src/plugins/html/html_document_encoder.dart';
import 'package:appflowy_editor/src/plugins/markdown/decoder/document_markdown_decoder.dart';
import 'package:appflowy_editor/src/plugins/markdown/decoder/parser/custom_node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/document_markdown_encoder.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/image_node_parser.dart';
import 'package:appflowy_editor/src/plugins/markdown/encoder/parser/parser.dart';

export 'package:appflowy_editor/appflowy_editor.dart' show EditorState;

AppFlowyEditorHTMLCodec defaultHtmlCodec = AppFlowyEditorHTMLCodec(
  encodeParsers: [
    const HTMLTextNodeParser(),
    const HTMLBulletedListNodeParser(),
    const HTMLNumberedListNodeParser(),
    const HTMLTodoListNodeParser(),
    const HTMLQuoteNodeParser(),
    const HTMLHeadingNodeParser(),
  ],
);
AppFlowyEditorMarkdownCodec defaultMarkdownCodec = AppFlowyEditorMarkdownCodec(
  encodeParsers: [
    const TextNodeParser(),
    const BulletedListNodeParser(),
    const NumberedListNodeParser(),
    const TodoListNodeParser(),
    const QuoteNodeParser(),
    const CodeBlockNodeParser(),
    const HeadingNodeParser(),
    const ImageNodeParser(),
    const TableNodeParser(),
  ],
);

extension ActerEditorStateHelpers on EditorState {
  static EditorState fromHtml(
    String content, {
    AppFlowyEditorHTMLCodec? codec,
  }) {
    return EditorState(document: (codec ?? defaultHtmlCodec).decode(content));
  }

  static EditorState fromMarkdown(
    String content, {
    AppFlowyEditorMarkdownCodec? codec,
  }) {
    return EditorState(
        document: (codec ?? defaultMarkdownCodec).decode(content));
  }

  String intoHtml({
    AppFlowyEditorHTMLCodec? codec,
  }) {
    return (codec ?? defaultHtmlCodec).encode(document);
  }

  String intoMarkdown({
    AppFlowyEditorMarkdownCodec? codec,
  }) {
    return (codec ?? defaultMarkdownCodec).encode(document);
  }
}

class HtmlEditor extends StatefulWidget {
  static const saveEditKey = Key('html-editor-save');
  static const cancelEditKey = Key('html-editor-cancel');

  final Widget? header;
  final Widget? footer;
  final bool autoFocus;
  final MsgContent? content;
  final Function(String, String?)? onSave;
  final Function()? onCancel;
  const HtmlEditor({
    Key? key,
    this.content,
    this.onSave,
    this.onCancel,
    this.autoFocus = true,
    this.header,
    this.footer,
  }) : super(key: key);

  @override
  _HtmlEditorState createState() => _HtmlEditorState();
}

class _HtmlEditorState extends State<HtmlEditor> {
  late EditorState editorState;

  @override
  void initState() {
    super.initState();
    final msgContent = widget.content;

    if (msgContent != null) {
      final formattedBody = msgContent.formattedBody();
      if (formattedBody != null) {
        editorState = ActerEditorStateHelpers.fromHtml(formattedBody);
      } else {
        editorState = ActerEditorStateHelpers.fromMarkdown(msgContent.body());
      }
    } else {
      editorState = EditorState.blank();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? finalFooter = widget.footer;
    if (finalFooter == null) {
      final List<Widget> children = [];

      if (widget.onCancel != null) {
        children.add(OutlinedButton(
          key: HtmlEditor.cancelEditKey,
          onPressed: widget.onCancel,
          child: const Text('cancel'),
        ));
      }
      final onSave = widget.onSave;
      if (onSave != null) {
        children.add(
          OutlinedButton(
            key: HtmlEditor.saveEditKey,
            onPressed: () {
              final plain = editorState.intoMarkdown();
              final htmlBody = editorState.intoHtml();
              onSave(
                plain,
                htmlBody != plain ? htmlBody : null,
              );
            },
            child: const Text('save'),
          ),
        );
      }

      if (children.isNotEmpty) {
        finalFooter = Wrap(
          alignment: WrapAlignment.end,
          children: children,
        );
      }
    }
    return AppFlowyEditor(
      editorState: editorState,
      autoFocus: widget.autoFocus,
      header: widget.header,
      footer: finalFooter,
    );
  }
}
