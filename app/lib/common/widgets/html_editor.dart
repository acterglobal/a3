import 'dart:async';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

AppFlowyEditorHTMLCodec defaultHtmlCodec = const AppFlowyEditorHTMLCodec(
  encodeParsers: [
    HTMLTextNodeParser(),
    HTMLBulletedListNodeParser(),
    HTMLNumberedListNodeParser(),
    HTMLTodoListNodeParser(),
    HTMLQuoteNodeParser(),
    HTMLHeadingNodeParser(),
    HtmlTableNodeParser(),
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

typedef ExportCallback = Function(String, String?);

class HtmlEditor extends StatefulWidget {
  static const saveEditKey = Key('html-editor-save');
  static const cancelEditKey = Key('html-editor-cancel');

  final Alignment alignment;
  final Widget? header;
  final Widget? footer;
  final bool autoFocus;
  final bool editable;
  final bool shrinkWrap;
  final EdgeInsets? editorPadding;
  final MsgContent? content;
  final TextStyleConfiguration? textStyleConfiguration;
  final String? initialHtml;
  final String? initialMarkdown;
  final ExportCallback? onSave;
  final ExportCallback? onChanged;
  final Function()? onCancel;
  const HtmlEditor({
    super.key,
    this.alignment = Alignment.topLeft,
    this.content,
    this.initialHtml,
    this.initialMarkdown,
    this.onSave,
    this.onChanged,
    this.onCancel,
    this.textStyleConfiguration,
    this.autoFocus = true,
    this.editable = false,
    this.shrinkWrap = false,
    this.editorPadding = const EdgeInsets.all(10),
    this.header,
    this.footer,
  });

  @override
  HtmlEditorState createState() => HtmlEditorState();
}

class HtmlEditorState extends State<HtmlEditor> {
  late EditorState editorState;
  late final EditorScrollController editorScrollController;
  final TextDirection _textDirection = TextDirection.ltr;
  // we store this to the stream stays alive
  // ignore: unused_field
  StreamSubscription<(TransactionTime, Transaction)>? _changeListener;

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
    } else if (widget.initialHtml != null) {
      editorState = ActerEditorStateHelpers.fromHtml(widget.initialHtml!);
    } else if (widget.initialMarkdown != null) {
      editorState =
          ActerEditorStateHelpers.fromMarkdown(widget.initialMarkdown!);
    } else {
      editorState = EditorState.blank();
    }

    editorScrollController = EditorScrollController(
      editorState: editorState,
      shrinkWrap: widget.shrinkWrap,
    );

    if (widget.onChanged != null) {
      _changeListener = editorState.transactionStream.listen((event) {
        _triggerExport(widget.onChanged!);
      });
    }
  }

  @override
  void dispose() {
    editorScrollController.dispose();
    editorState.dispose();

    super.dispose();
  }

  void _triggerExport(ExportCallback exportFn) {
    final plain = editorState.intoMarkdown();
    final htmlBody = editorState.intoHtml();
    exportFn(plain, htmlBody != plain ? htmlBody : null);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = desktopPlatforms.contains(Theme.of(context).platform);
    return isDesktop ? desktopEditor() : mobileEditor();
  }

  Widget? generateFooter() {
    if (widget.footer != null) {
      return widget.footer;
    }
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
    if (widget.onSave != null) {
      children.add(
        ElevatedButton(
          key: HtmlEditor.saveEditKey,
          onPressed: () => _triggerExport(widget.onSave!),
          child: const Text('Save'),
        ),
      );
    }

    if (children.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: children,
        ),
      );
    }
    return null;
  }

  Widget desktopEditor() {
    return FloatingToolbar(
      items: [
        paragraphItem,
        ...headingItems,
        ...markdownFormatItems,
        quoteItem,
        bulletedListItem,
        numberedListItem,
        linkItem,
        buildHighlightColorItem(),
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
          // widget pass through
          editable: widget.editable,
          shrinkWrap: widget.shrinkWrap,
          autoFocus: widget.autoFocus,
          header: widget.header,
          // local states
          editorScrollController: editorScrollController,
          editorState: editorState,
          editorStyle: desktopEditorStyle(),
          footer: generateFooter(),
        ),
      ),
    );
  }

  Widget mobileEditor() {
    return MobileToolbarV2(
      toolbarItems: [
        textDecorationMobileToolbarItemV2,
        buildTextAndBackgroundColorMobileToolbarItem(
          textColorOptions: [],
        ),
        headingMobileToolbarItem,
        listMobileToolbarItem,
        linkMobileToolbarItem,
        quoteMobileToolbarItem,
      ],
      editorState: editorState,
      child: MobileFloatingToolbar(
        editorScrollController: editorScrollController,
        editorState: editorState,
        toolbarBuilder: (context, anchor, closeToolbar) {
          return AdaptiveTextSelectionToolbar.editable(
            clipboardStatus: ClipboardStatus.pasteable,
            onCopy: () {
              copyCommand.execute(editorState);
              closeToolbar();
            },
            onCut: () => cutCommand.execute(editorState),
            onPaste: () => pasteCommand.execute(editorState),
            onSelectAll: () => selectAllCommand.execute(editorState),
            onLiveTextInput: null,
            onLookUp: null,
            onSearchWeb: null,
            onShare: null,
            anchors: TextSelectionToolbarAnchors(
              primaryAnchor: anchor,
            ),
          );
        },
        child: AppFlowyEditor(
          // widget pass through
          editable: widget.editable,
          shrinkWrap: widget.shrinkWrap,
          autoFocus: widget.autoFocus,
          header: widget.header,
          // local states
          editorState: editorState,
          editorScrollController: editorScrollController,
          editorStyle: mobileEditorStyle(),
          footer: generateFooter(),
        ),
      ),
    );
  }

  EditorStyle desktopEditorStyle() {
    return EditorStyle.desktop(
      padding: widget.editorPadding,
      cursorColor: Theme.of(context).colorScheme.primary,
      selectionColor: Theme.of(context).colorScheme.neutral,
      textStyleConfiguration: widget.textStyleConfiguration ??
          TextStyleConfiguration(
            text: Theme.of(context).textTheme.bodySmall!,
          ),
    );
  }

  EditorStyle mobileEditorStyle() {
    return EditorStyle.mobile(
      padding: widget.editorPadding,
      cursorColor: Theme.of(context).colorScheme.primary,
      selectionColor: Theme.of(context).colorScheme.neutral,
      textStyleConfiguration: widget.textStyleConfiguration ??
          TextStyleConfiguration(
            text: Theme.of(context).textTheme.bodySmall!,
          ),
    );
  }
}
