import 'dart:async';
import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/html_editor/mentions/commands/backspace_for_mentions.dart';
import 'package:acter/common/toolkit/html_editor/mentions/mention_detection.dart';
import 'package:acter/common/toolkit/html_editor/services/utils.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:acter/common/toolkit/html_editor/mentions/mention_shortcuts.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
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
      lineBreak: ' ',
    );

// contains final input string with mentions processed and mentions
typedef MentionParsedText = (String, List<String>);

extension ActerEditorStateHelpers on EditorState {
  /// helper to parse mentions from editor text
  List<String> getMentions(String plainText, String? htmlText) {
    List<String> mentionIds = [];
    int index = 0;
    while (true) {
      final node = document.nodeAtPath([index]);
      if (node == null) break;

      final delta = node.delta;
      if (delta != null) {
        for (final op in delta) {
          if (op.attributes != null) {
            final href = op.attributes?[AppFlowyRichTextKeys.href] as String?;
            if (href != null) {
              final uri = Uri.tryParse(href);
              if (uri != null) {
                final parsed = parseActerUri(uri);
                if (parsed.type == LinkType.userId ||
                    parsed.type == LinkType.roomId) {
                  mentionIds.add(parsed.target);
                }
              }
            }
          }
        }
      }
      index++;
    }

    return mentionIds;
  }

  /// copy message content to editor
  void copyMessageText(String text, String? htmlText) async {
    clear();

    if (htmlText != null && htmlText.isNotEmpty) {
      //  normalize html to appflowy html, before decoding
      htmlText = normalizeToAppflowyHtml(htmlText);

      final doc = defaultHtmlCodec.decode(htmlText);
      final transaction = this.transaction;
      transaction.insertNodes([0], doc.root.children);
      apply(transaction);
    } else {
      final transaction = this.transaction;
      transaction.insertNode([0], paragraphNode(text: text));
      apply(transaction);
    }

    var lastNode = document.root.children.lastWhere(
      (node) => node.delta?.toPlainText().isNotEmpty ?? false,
      orElse: () => document.root.children.last,
    );

    final path = lastNode.path;
    final offset = lastNode.delta?.length ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateSelectionWithReason(
        Selection.single(path: path, startOffset: offset),
        reason: SelectionUpdateReason.uiEvent,
      );
    });
  }

  String intoMarkdown({AppFlowyEditorMarkdownCodec? codec}) {
    return (codec ?? defaultMarkdownCodec).encode(document);
  }

  String intoHtml({AppFlowyEditorHTMLCodec? codec}) {
    return (codec ?? defaultHtmlCodec).encode(document);
  }

  /// clear the editor text with selection
  void clear() async {
    if (!document.isEmpty) {
      final transaction = this.transaction;

      // Delete all existing nodes
      int nodeIndex = 0;
      while (true) {
        final node = getNodeAtPath([nodeIndex]);
        if (node == null) break;
        transaction.deleteNode(node);
        nodeIndex++;
      }

      transaction.insertNode([0], paragraphNode(text: ''));

      apply(transaction);

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

class HtmlEditor extends StatefulWidget {
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
  State<HtmlEditor> createState() => _HtmlEditorState();
}

const innerPadding = 24.0;
const defaultMinHeight = 40.0;
const defaultMaxHeight = 200.0;

class _HtmlEditorState extends State<HtmlEditor> {
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

  @override
  void didUpdateWidget(covariant HtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorState != widget.editorState) {
      updateEditorState(widget.editorState ?? EditorState.blank());
    }
  }

  @override
  void dispose() {
    editorScrollController.visibleRangeNotifier.removeListener(
      _updateEditorHeight,
    );
    _changeListener?.cancel();
    super.dispose();
  }

  void updateEditorState(EditorState newEditorState) {
    editorState = newEditorState;

    editorScrollController = EditorScrollController(
      editorState: editorState,
      shrinkWrap: widget.shrinkWrap,
    );

    editorScrollController.visibleRangeNotifier.addListener(
      _updateEditorHeight,
    );

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

  void _updateEditorHeight() {
    final scrollService = editorState.scrollableState;
    if (scrollService == null) {
      _contentHeightNotifier.value = widget.minHeight ?? defaultMinHeight;
      return;
    }

    final position = scrollService.position;
    final viewportDimension = position.viewportDimension;

    if (viewportDimension <= 0) {
      _contentHeightNotifier.value = widget.minHeight ?? defaultMinHeight;
      return;
    }

    // count paragraph nodes
    final document = editorState.document;
    final paragraphCount = document.root.children.length;

    double lineHeight = Theme.of(context).textTheme.bodySmall?.fontSize ?? 14.0;
    double contentHeight = widget.minHeight ?? defaultMinHeight;
    if (paragraphCount > 1) {
      contentHeight += innerPadding + (paragraphCount - 1) * lineHeight;
    }

    // also account for viewport
    double calculatedHeight = max(contentHeight, viewportDimension);

    // smaller than viewport, shrink to content size
    if (contentHeight < viewportDimension && position.maxScrollExtent <= 0) {
      calculatedHeight = contentHeight;
    }

    if (widget.maxHeight != null) {
      calculatedHeight = min(
        calculatedHeight,
        widget.maxHeight ?? defaultMaxHeight,
      );
    }
    calculatedHeight = max(
      calculatedHeight,
      widget.minHeight ?? defaultMinHeight,
    );

    _contentHeightNotifier.value = calculatedHeight;
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
      if (widget.roomId != null) ...mentionShortcuts(context, widget.roomId!),
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
        backSpaceCommandForMentions,
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
