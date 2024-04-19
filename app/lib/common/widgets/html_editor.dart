import 'dart:async';

import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
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

extension ActerDocumentHelpers on Document {
  static Document fromHtml(
    String content, {
    AppFlowyEditorHTMLCodec? codec,
  }) {
    return (codec ?? defaultHtmlCodec).decode(content);
  }

  static Document fromMarkdown(
    String content, {
    AppFlowyEditorMarkdownCodec? codec,
  }) {
    return (codec ?? defaultMarkdownCodec).decode(content);
  }

  static Document fromMsgContent(MsgContent msgContent) {
    final formattedBody = msgContent.formattedBody();
    if (formattedBody != null) {
      return ActerDocumentHelpers.fromHtml(formattedBody);
    } else {
      return ActerDocumentHelpers.fromMarkdown(msgContent.body());
    }
  }
}

typedef ExportCallback = Function(String, String?);

class HtmlEditor extends StatefulWidget {
  static const saveEditKey = Key('html-editor-save');
  static const cancelEditKey = Key('html-editor-cancel');

  final Widget? header;
  final Widget? footer;
  final bool autoFocus;
  final bool editable;
  final bool shrinkWrap;
  final EditorState? editorState;
  final EdgeInsets? editorPadding;
  final TextStyleConfiguration? textStyleConfiguration;
  final ExportCallback? onSave;
  final ExportCallback? onChanged;
  final Function()? onCancel;
  const HtmlEditor({
    super.key,
    this.editorState,
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
  late EditorScrollController editorScrollController;
  final TextDirection _textDirection = TextDirection.ltr;
  // we store this to the stream stays alive
  StreamSubscription<(TransactionTime, Transaction)>? _changeListener;

  @override
  void initState() {
    super.initState();
    updateEditorState(widget.editorState ?? EditorState.blank());
  }

  void updateEditorState(EditorState newEditorState) {
    setState(() {
      editorState = newEditorState;

      if (widget.editable && widget.autoFocus) {
        editorState.updateSelectionWithReason(
          Selection.single(
            path: [0],
            startOffset: 0,
          ),
          reason: SelectionUpdateReason.uiEvent,
        );
      }

      editorScrollController = EditorScrollController(
        editorState: editorState,
        shrinkWrap: widget.shrinkWrap,
      );

      _changeListener?.cancel();
      if (widget.onChanged != null) {
        _changeListener = editorState.transactionStream.listen((event) {
          _triggerExport(widget.onChanged!);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant HtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorState != widget.editorState) {
      updateEditorState(widget.editorState ?? EditorState.blank());
    }
  }

  @override
  void dispose() {
    editorScrollController.dispose();
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
        ActerPrimaryActionButton(
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
