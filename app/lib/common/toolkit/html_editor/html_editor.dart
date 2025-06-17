import 'dart:async';
import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/html/utils.dart';
import 'package:acter/common/toolkit/html_editor/mentions/commands/mention_movements.dart';
import 'package:acter/common/toolkit/html_editor/mentions/mention_detection.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:acter/common/toolkit/html_editor/mentions/mention_shortcuts.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::html_editor');

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
  String intoMarkdown({AppFlowyEditorMarkdownCodec? codec}) {
    return (codec ?? defaultMarkdownCodec).encode(document).trim();
  }

  String intoHtml({AppFlowyEditorHTMLCodec? codec}) {
    return (codec ?? defaultHtmlCodec).encode(document);
  }

  static EditorState fromContent(String fallbackPlain, String? properHtml) =>
      EditorState(
        document: defaultHtmlCodec.decode(
          properHtml != null && properHtml.isNotEmpty
              ? properHtml
              : minimalMarkup(fallbackPlain),
        ),
      );

  void replaceContent(String fallbackPlain, String? properHtml) =>
      replaceContentHTML(
        properHtml != null && properHtml.isNotEmpty
            ? properHtml
            : minimalMarkup(fallbackPlain),
      );

  void replaceContentHTML(String body) {
    // I would have expected a transaction can do both delete and insert Nodes
    // but if we do that within the exact same transation, for an unknown reason,
    // the order of the inserted Items is then messed up. See
    //            https://github.com/AppFlowy-IO/appflowy-editor/issues/1122
    // That's why we do that in two separate transactions.

    Transaction t = transaction;
    t.deleteNodes(document.root.children); // drop previous children
    apply(t);

    t = transaction;
    bool inserted = false;

    if (body.isNotEmpty) {
      final newDoc = defaultHtmlCodec.decode(body);
      if (newDoc.root.children.isNotEmpty) {
        t.insertNodes([0], newDoc.root.children);
        inserted = true;
      }
    }

    if (!inserted) {
      // per fallback we add one empty paragraph
      t.insertNode([0, 0], paragraphNode());
    }

    apply(t);
  }

  /// clear the editor text with selection
  void clear() async {
    if (!document.isEmpty) {
      final t = transaction;
      t.deleteNodes(document.root.children); // clear the page
      apply(t);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateSelectionWithReason(
          Selection.single(path: [0], startOffset: 0, endOffset: 0),
          reason: SelectionUpdateReason.uiEvent,
        );
      });
    }
  }
}

typedef ExportCallback = Function(String, String?);

class HtmlEditor extends ConsumerStatefulWidget {
  static const saveEditKey = Key('html-editor-save');
  static const cancelEditKey = Key('html-editor-cancel');
  final String? roomId;
  final String? hintText;
  final Widget? header;
  final Widget? footer;
  final double? minHeight;
  final double? maxHeight;
  final bool editable;
  final bool shrinkWrap;
  final bool disableAutoScroll;
  final EditorState? editorState;
  final TextStyleConfiguration? textStyleConfiguration;
  final ExportCallback? onSave;
  final ExportCallback? onChanged;
  final Function()? onCancel;

  const HtmlEditor({
    super.key,
    this.roomId,
    this.editorState,
    this.hintText = '',
    this.onSave,
    this.onChanged,
    this.onCancel,
    this.textStyleConfiguration,
    this.editable = false,
    this.shrinkWrap = false,
    this.disableAutoScroll = false,
    this.header,
    this.footer,
    this.minHeight,
    this.maxHeight,
  });

  @override
  ConsumerState<HtmlEditor> createState() => _HtmlEditorState();
}

const innnerMargin = 10.0;
const defaultMinHeight = 40.0;
const lineHeight = 16.0;

class _HtmlEditorState extends ConsumerState<HtmlEditor> {
  late EditorState editorState;
  late EditorScrollController editorScrollController;

  late ValueNotifier<double> _contentHeightNotifier;
  StreamSubscription<EditorTransactionValue>? _changeListener;

  @override
  void initState() {
    super.initState();
    _contentHeightNotifier = ValueNotifier(
      widget.minHeight ?? defaultMinHeight,
    );
    AppFlowyRichTextKeys.partialSliced.addAll([
      userMentionChar,
      roomMentionChar,
    ]);

    updateEditorState(widget.editorState ?? EditorState.blank());
  }

  void updateEditorState(EditorState newEditorState) {
    editorState = newEditorState;

    editorScrollController = EditorScrollController(
      editorState: editorState,
      shrinkWrap: widget.shrinkWrap,
    );

    // Listen to all editor transactions with a delay
    editorState.transactionStream.listen((_) {
      Future.delayed(const Duration(milliseconds: 50), _updateContentHeight);
    });

    _changeListener?.cancel();
    widget.onChanged.map((cb) {
      _changeListener = editorState.transactionStream.listen(
        (data) => _triggerExport(cb),
        onError: (e, s) {
          _log.severe('tx stream errored', e, s);
        },
        onDone: () {
          _log.info('tx stream ended');
        },
      );
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
    _changeListener?.cancel();
    super.dispose();
  }

  void _updateContentHeight() {
    final contentHeight = _calculateContentHeight();

    double newHeight = contentHeight;
    final maxHeight = widget.maxHeight;
    if (maxHeight != null) {
      newHeight = min(newHeight, maxHeight);
    }
    final minHeight = widget.minHeight ?? defaultMinHeight;
    newHeight = max(newHeight, minHeight);

    if ((_contentHeightNotifier.value - newHeight).abs() > 1.0) {
      _contentHeightNotifier.value = newHeight;
    }
  }

  double _calculateContentHeight() {
    final scrollService = editorState.scrollableState;
    if (scrollService == null) return widget.minHeight ?? defaultMinHeight;

    final textWidth = scrollService.position.viewportDimension;
    if (textWidth <= 0) return widget.minHeight ?? defaultMinHeight;

    final textContent = editorState.document.root.children
        .map((node) => node.delta?.toPlainText() ?? '')
        .join('\n');

    if (textContent.isEmpty) {
      return defaultMinHeight;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: textContent,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: textWidth);

    return textPainter.height + (2 * innnerMargin);
  }

  void _triggerExport(ExportCallback exportFn) {
    final plain = editorState.intoMarkdown();
    final htmlBody = editorState.intoHtml();

    exportFn(plain, htmlBody != plain ? htmlBody : null);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = desktopPlatforms.contains(Theme.of(context).platform);
    final roomId = widget.roomId;
    return isDesktop ? desktopEditor(roomId) : mobileEditor(roomId);
  }

  Map<String, BlockComponentBuilder> _buildBlockComponentBuilders() {
    final map = {...standardBlockComponentBuilderMap};
    map[ParagraphBlockKeys.type] = ParagraphBlockComponentBuilder(
      showPlaceholder: (editorState, node) => editorState.document.isEmpty,
      configuration: BlockComponentConfiguration(
        placeholderText: (node) => widget.hintText ?? '',
        padding: (node) => EdgeInsets.zero,
      ),
    );

    return map;
  }

  List<CharacterShortcutEvent> _buildCharacterShortcutEvents() {
    return [
      ...standardCharacterShortcutEvents.where((e) => e != slashCommand),
      if (widget.roomId != null)
        ...mentionShortcuts(context, ref, widget.roomId!),
    ];
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
    children.add(const SizedBox(width: 10));
    widget.onSave.map((cb) {
      children.add(
        ActerPrimaryActionButton(
          key: HtmlEditor.saveEditKey,
          onPressed: () => _triggerExport(cb),
          child: const Text('Save'),
        ),
      );
    });

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

  Widget desktopEditor(String? roomId) => FloatingToolbar(
    items: [
      paragraphItem,
      ...headingItems,
      ...markdownFormatItems,
      quoteItem,
      bulletedListItem,
      numberedListItem,
      linkItem,
    ],
    textDirection: Directionality.of(context),
    editorState: editorState,
    editorScrollController: editorScrollController,
    style: FloatingToolbarStyle(
      backgroundColor: Theme.of(context).colorScheme.surface,
      toolbarActiveColor: Theme.of(context).colorScheme.tertiary,
    ),
    child: Directionality(
      textDirection: Directionality.of(context),
      child: _editor(editorStyle: desktopEditorStyle(), autoFocus: true),
    ),
  );

  Widget mobileEditor(String? roomId) {
    return MobileToolbarV2(
      backgroundColor: Theme.of(context).colorScheme.surface,
      iconColor: Theme.of(context).colorScheme.onSurface,
      primaryColor: Theme.of(context).colorScheme.primary,
      onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
      borderRadius: 0.0,
      buttonBorderWidth: 0.0,
      buttonSelectedBorderWidth: 0.0,
      buttonSpacing: 4.0,
      buttonHeight: 20.0,
      itemOutlineColor: Theme.of(context).colorScheme.surface,
      toolbarItems: [
        textDecorationMobileToolbarItem,
        headingMobileToolbarItem,
        listMobileToolbarItem,
        linkMobileToolbarItem,
        quoteMobileToolbarItem,
        codeMobileToolbarItem,
      ],
      toolbarHeight: 40,
      editorState: editorState,
      child: MobileFloatingToolbar(
        editorScrollController: editorScrollController,
        editorState: editorState,
        floatingToolbarHeight: 50,
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
            anchors: TextSelectionToolbarAnchors(primaryAnchor: anchor),
          );
        },
        child: _editor(editorStyle: mobileEditorStyle(), autoFocus: false),
      ),
    );
  }

  Widget _editor({required EditorStyle editorStyle, required bool autoFocus}) {
    final editor = AppFlowyEditor(
      // widget pass through
      editable: widget.editable,
      shrinkWrap: widget.shrinkWrap,
      autoFocus: autoFocus,
      header: widget.header,
      // local states
      editorState: editorState,
      editorScrollController: editorScrollController,
      editorStyle: editorStyle,
      footer: generateFooter(),
      blockComponentBuilders: _buildBlockComponentBuilders(),
      characterShortcutEvents: _buildCharacterShortcutEvents(),
      commandShortcutEvents: [
        ...mentionMenuCommandShortcutEvents,
        ...standardCommandShortcutEvents,
      ],
      disableAutoScroll: false,
      autoScrollEdgeOffset: 20,
    );

    if (widget.maxHeight == null && widget.minHeight == null) {
      return editor;
    }

    return ValueListenableBuilder(
      valueListenable: _contentHeightNotifier,
      builder:
          (context, value, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            width: MediaQuery.sizeOf(context).width,
            height: max(value, widget.minHeight ?? 50),
            child: editor,
          ),
    );
  }

  EditorStyle desktopEditorStyle() {
    return EditorStyle.desktop(
      padding: EdgeInsets.zero,
      cursorColor: Theme.of(context).colorScheme.primary,
      selectionColor: Theme.of(context).colorScheme.secondary,
      textStyleConfiguration:
          widget.textStyleConfiguration ??
          TextStyleConfiguration(
            text: Theme.of(
              context,
            ).textTheme.bodySmall.expect('bodySmall style not available'),
            lineHeight: 1.0,
          ),
      textSpanDecorator:
          widget.roomId != null ? customizeAttributeDecorator : null,
    );
  }

  EditorStyle mobileEditorStyle() {
    return EditorStyle.mobile(
      padding: EdgeInsets.zero,
      cursorColor: Theme.of(context).colorScheme.primary,
      selectionColor: Theme.of(context).colorScheme.secondary,
      textStyleConfiguration:
          widget.textStyleConfiguration ??
          TextStyleConfiguration(
            text: Theme.of(
              context,
            ).textTheme.bodySmall.expect('bodySmall style not available'),
            lineHeight: 1.0,
          ),
      textSpanDecorator:
          widget.roomId != null ? customizeAttributeDecorator : null,
    );
  }

  InlineSpan customizeAttributeDecorator(
    BuildContext context,
    Node node,
    int index,
    TextInsert text,
    TextSpan before,
    TextSpan after,
  ) {
    // fast track if there are no attributes
    final attributes = text.attributes;
    if (attributes == null) {
      return before;
    }

    final roomId = widget.roomId;
    final parsed = getMentionForInsert(text);

    if (parsed != null) {
      final inner = switch (parsed.type) {
        (LinkType.userId) => UserChip(roomId: roomId, memberId: parsed.target),
        (LinkType.roomId) => RoomChip(roomId: parsed.target),
        (LinkType.spaceObject) => InlineItemPreview(
          roomId: roomId,
          uriResult: parsed,
        ),
        _ => null,
      };
      if (inner != null) {
        return WidgetSpan(alignment: PlaceholderAlignment.middle, child: inner);
      }
    }

    // fallback to the default behavior
    return defaultTextSpanDecoratorForAttribute(
      context,
      node,
      index,
      text,
      before,
      after,
    );
  }
}
