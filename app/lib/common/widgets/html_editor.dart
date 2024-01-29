import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

export 'package:appflowy_editor/appflowy_editor.dart' show EditorState;

AppFlowyEditorHTMLCodec defaultHtmlCodec = const AppFlowyEditorHTMLCodec(
  encodeParsers: [
    HTMLTextNodeParser(),
    HTMLBulletedListNodeParser(),
    HTMLNumberedListNodeParser(),
    HTMLTodoListNodeParser(),
    HTMLQuoteNodeParser(),
    HTMLHeadingNodeParser(),
  ],
);
AppFlowyEditorMarkdownCodec defaultMarkdownCodec =
    const AppFlowyEditorMarkdownCodec(
  encodeParsers: [
    TextNodeParser(),
    BulletedListNodeParser(),
    NumberedListNodeParser(),
    TodoListNodeParser(),
    QuoteNodeParser(),
    CodeBlockNodeParser(),
    HeadingNodeParser(),
    ImageNodeParser(),
    TableNodeParser(),
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
      document: (codec ?? defaultMarkdownCodec).decode(content),
    );
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
  final EdgeInsets? editorPadding;
  final MsgContent? content;
  final bool editable;
  final Function(String, String?)? onSave;
  final Function()? onCancel;
  const HtmlEditor({
    super.key,
    this.content,
    this.onSave,
    this.onCancel,
    this.autoFocus = true,
    this.editable = true,
    this.editorPadding = const EdgeInsets.all(10),
    this.header,
    this.footer,
  });
  @override
  // ignore: library_private_types_in_public_api
  _HtmlEditorState createState() => _HtmlEditorState();
}

class _HtmlEditorState extends State<HtmlEditor> {
  late EditorState editorState;
  late final EditorScrollController editorScrollController;
  final TextDirection _textDirection = TextDirection.ltr;

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

    editorScrollController = EditorScrollController(
      editorState: editorState,
      shrinkWrap: true,
    );
  }

  @override
  void dispose() {
    editorScrollController.dispose();
    editorState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? finalFooter = widget.footer;
    if (finalFooter == null) {
      final List<Widget> children = [];

      if (widget.onCancel != null) {
        children.add(
          OutlinedButton(
            key: HtmlEditor.cancelEditKey,
            onPressed: widget.onCancel,
            child: const Text('Cancel'),
          ),
        );
      }
      children.add(
        const SizedBox(
          width: 10,
        ),
      );
      final onSave = widget.onSave;
      if (onSave != null) {
        children.add(
          ElevatedButton(
            key: HtmlEditor.saveEditKey,
            onPressed: () {
              final plain = editorState.intoMarkdown();
              final htmlBody = editorState.intoHtml();
              onSave(
                plain,
                htmlBody != plain ? htmlBody : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.success,
            ),
            child: const Text('Save'),
          ),
        );
      }

      if (children.isNotEmpty) {
        finalFooter = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: children,
        );
      }
    }

    return isLargeScreen(context)
        ? FloatingToolbar(
            items: [
              paragraphItem,
              ...headingItems,
              ...markdownFormatItems,
              quoteItem,
              bulletedListItem,
              numberedListItem,
              linkItem,
              buildTextColorItem(),
              buildHighlightColorItem(),
              ...textDirectionItems,
              ...alignmentItems,
            ],
            textDirection: _textDirection,
            editorState: editorState,
            editorScrollController: editorScrollController,
            style: FloatingToolbarStyle(
              backgroundColor: Theme.of(context).colorScheme.neutral2,
              toolbarActiveColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: Directionality(
              textDirection: _textDirection,
              child: AppFlowyEditor(
                editable: widget.editable,
                shrinkWrap: true,
                editorStyle: customEditorStyle(true),
                editorScrollController: editorScrollController,
                editorState: editorState,
                autoFocus: widget.autoFocus,
                header: widget.header,
                footer: finalFooter,
              ),
            ),
          )
        : AppFlowyEditor(
            editorStyle: customEditorStyle(false),
            editorState: editorState,
            autoFocus: widget.autoFocus,
            header: widget.header,
            footer: finalFooter,
          );
  }

  EditorStyle customEditorStyle(bool isDesktop) {
    return isLargeScreen(context)
        ? EditorStyle.desktop(
            padding: widget.editorPadding,
            cursorColor: Theme.of(context).colorScheme.primary,
            selectionColor: Theme.of(context).colorScheme.neutral,
            textStyleConfiguration: TextStyleConfiguration(
              text: Theme.of(context).textTheme.bodySmall!,
            ),
          )
        : EditorStyle.mobile(
            padding: widget.editorPadding,
            cursorColor: Theme.of(context).colorScheme.primary,
            selectionColor: Theme.of(context).colorScheme.neutral6,
            textStyleConfiguration: TextStyleConfiguration(
              text: Theme.of(context).textTheme.bodySmall!,
            ),
          );
  }
}
