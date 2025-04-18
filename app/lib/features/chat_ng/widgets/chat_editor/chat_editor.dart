import 'dart:async';
import 'dart:math';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/actions/attachment_upload_action.dart';
import 'package:acter/features/chat_ng/actions/send_message_action.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor_actions_preview.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_emoji_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';

// Chat Input Field Widget
final _log = Logger('a3::chat::chat_editor');

class ChatEditor extends ConsumerStatefulWidget {
  static const sendBtnKey = Key('editor-send-button');
  final String roomId;
  final void Function(bool)? onTyping;
  const ChatEditor({super.key, required this.roomId, this.onTyping});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatEditorState();
}

class _ChatEditorState extends ConsumerState<ChatEditor> {
  EditorState textEditorState = EditorState.blank();
  late EditorScrollController scrollController;
  StreamSubscription<EditorTransactionValue>? _updateListener;
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);
  final ValueNotifier<double> _contentHeightNotifier = ValueNotifier(56.0);
  Timer? _debounceTimer;
  Timer? _heightDebounceTimer;

  @override
  void initState() {
    super.initState();
    scrollController = EditorScrollController(editorState: textEditorState);
    _updateListener?.cancel();
    // listener for editor input state
    _updateListener = textEditorState.transactionStream.listen((data) {
      _editorUpdate(data.$2);

      _updateContentHeight();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());

    ref.listenManual(chatEditorStateProvider, (prev, next) async {
      final body = textEditorState.intoMarkdown();
      final bodyHtml = textEditorState.intoHtml();
      if (next.isEditing &&
          (next.actionType != prev?.actionType ||
              next.selectedMsgItem != prev?.selectedMsgItem)) {
        _handleEditing(next.selectedMsgItem);
      }
      if (next.isReplying &&
          (next.actionType != prev?.actionType ||
              next.selectedMsgItem != prev?.selectedMsgItem)) {
        textEditorState.updateSelectionWithReason(
          Selection.single(
            path: [0],
            startOffset: textEditorState.intoMarkdown().length - 1,
          ),
          reason: SelectionUpdateReason.uiEvent,
        );
        saveMsgDraft(body, bodyHtml, widget.roomId, ref);
      }
    });
  }

  @override
  void dispose() {
    _updateListener?.cancel();
    _debounceTimer?.cancel();
    _heightDebounceTimer?.cancel();
    _contentHeightNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
    }
  }

  void _handleEditing(TimelineEventItem? item) {
    if (item == null) return;

    final msgContent = item.message();
    if (msgContent == null) return;

    final body = msgContent.body();
    if (body.isEmpty) return;
    // clear the editor first
    textEditorState.clear();

    final docNode = textEditorState.getNodeAtPath([0]);
    if (docNode == null) return;

    // process text and apply mention attributes , if any
    textEditorState.toMentionPills(body, docNode);

    final text = docNode.delta?.toPlainText() ?? '';
    final pos = Position(path: [0], offset: text.length);
    textEditorState.updateSelectionWithReason(
      Selection.collapsed(pos),
      reason: SelectionUpdateReason.uiEvent,
    );

    _updateContentHeight();
  }

  void _editorUpdate(Transaction data) {
    final plainText = textEditorState.intoMarkdown();
    final html = textEditorState.intoHtml();

    _isInputEmptyNotifier.value =
        !hasValidEditorContent(plainText: plainText, html: html);

    _debounceTimer?.cancel();
    // delay operation to avoid excessive re-writes
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // save composing draft
      final text = textEditorState.intoMarkdown();
      final htmlText = textEditorState.intoHtml();
      await saveMsgDraft(text, htmlText, widget.roomId, ref);
      _log.info('compose draft saved for room: ${widget.roomId}');
    });
  }

  // composer draft load state handler
  Future<void> _loadDraft() async {
    final draft = await ref.read(
      chatComposerDraftProvider(widget.roomId).future,
    );

    if (draft != null) {
      final chatEditorState = ref.read(chatEditorStateProvider.notifier);
      chatEditorState.unsetActions();
      textEditorState.clear();
      final body = draft.plainText();
      draft.eventId().map((eventId) {
        final draftType = draft.draftType();
        final msgsList =
            ref.read(chatMessagesStateProvider(widget.roomId)).messages;
        try {
          final roomMsg = msgsList[eventId];
          final item = roomMsg?.eventItem();
          if (item == null) return;
          if (draftType == 'edit') {
            chatEditorState.setEditMessage(item);
          } else if (draftType == 'reply') {
            chatEditorState.setReplyToMessage(item);
          }
        } catch (e) {
          _log.severe('Message with $eventId not found');
          return;
        }
      });

      if (body.trim().isEmpty) return;

      final transaction = textEditorState.transaction;
      final docNode = textEditorState.getNodeAtPath([0]);
      if (docNode == null) return;
      transaction.replaceText(docNode, 0, docNode.delta?.length ?? 0, body);
      final pos = Position(path: [0], offset: body.length);
      transaction.afterSelection = Selection.collapsed(pos);
      textEditorState.apply(transaction);
      _log.info('compose draft loaded for room: ${widget.roomId}');
    }
  }

  void _updateContentHeight() {
    _heightDebounceTimer?.cancel();

    // use a timer to debounce multiple rapid updates
    _heightDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      final text = textEditorState.intoMarkdown();
      double newHeight = ChatEditorUtils.calculateContentHeight(text);
      newHeight = min(newHeight, 200.0);

      if (_contentHeightNotifier.value != newHeight) {
        _contentHeightNotifier.value = newHeight;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = ref.watch(keyboardVisibleProvider).valueOrNull;
    final emojiPickerVisible = ref.watch(
      chatInputProvider.select((value) => value.emojiPickerVisible),
    );
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(widget.roomId)).valueOrNull == true;
    final chatEditorState = ref.watch(chatEditorStateProvider);

    Widget? previewWidget;

    if (chatEditorState.isReplying || chatEditorState.isEditing) {
      final msgItem = chatEditorState.selectedMsgItem;
      previewWidget = msgItem.map(
        (item) => ChatEditorActionsPreview(
          textEditorState: textEditorState,
          msgItem: item,
          roomId: widget.roomId,
        ),
        orElse: () => const SizedBox.shrink(),
      );
    }

    return Column(
      children: <Widget>[
        if (previewWidget != null) previewWidget,
        ValueListenableBuilder<double>(
          valueListenable: _contentHeightNotifier,
          builder: (context, height, _) {
            return renderEditorUI(emojiPickerVisible, isEncrypted, height);
          },
        ),
        // Emoji Picker UI
        if (emojiPickerVisible) ChatEmojiPicker(editorState: textEditorState),
        // adjust bottom viewport so toolbar doesn't obscure field when visible
        if (isKeyboardVisible != null && isKeyboardVisible)
          SizedBox(height: viewInsets + 50),
      ],
    );
  }

  // chat editor UI
  Widget renderEditorUI(
    bool emojiPickerVisible,
    bool isEncrypted,
    double contentHeight,
  ) {
    final chatEditorState = ref.watch(chatEditorStateProvider);
    final isPreviewOpen =
        chatEditorState.isReplying || chatEditorState.isEditing;
    final radiusVal = isPreviewOpen ? 2.0 : 15.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: MediaQuery.sizeOf(context).width,
      height: contentHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radiusVal),
          topRight: Radius.circular(radiusVal),
        ),
        border: BorderDirectional(top: BorderSide(color: greyColor)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingBtn(emojiPickerVisible),
          editorField(isEncrypted),
          trailingBtn(),
        ],
      ),
    );
  }

  // emoji button
  Widget leadingBtn(bool emojiPickerVisible) {
    return IconButton(
      padding: const EdgeInsets.only(left: 12, top: 12),
      onPressed: () => _toggleEmojiPicker(emojiPickerVisible),
      icon: const Icon(Icons.emoji_emotions, size: 20),
    );
  }

  void _toggleEmojiPicker(bool emojiPickerVisible) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    chatInputNotifier.emojiPickerVisible(!emojiPickerVisible);
  }

  Widget editorField(bool isEncrypted) {
    final hintText = isEncrypted.map(
      (v) =>
          v == true
              ? L10n.of(context).newEncryptedMessage
              : L10n.of(context).newMessage,
      orElse: () => L10n.of(context).newMessage,
    );

    return Expanded(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter):
              () => sendMessageAction(
                roomId: widget.roomId,
                textEditorState: textEditorState,
                onTyping: widget.onTyping,
                context: context,
                ref: ref,
                log: _log,
              ),
          LogicalKeySet(LogicalKeyboardKey.enter, LogicalKeyboardKey.shift):
              () => textEditorState.insertNewLine(),
        },
        child: _renderEditor(hintText),
      ),
    );
  }

  Widget _renderEditor(String? hintText) {
    final needsScrolling =
        _contentHeightNotifier.value >
        ChatEditorUtils.scrollThreshold; // Threshold to enable auto scroll

    return HtmlEditor(
      footer: null,
      // if provided, will activate mentions
      roomId: widget.roomId,
      hintText: hintText,
      editable: true,
      shrinkWrap: needsScrolling,
      // only enable scrolling when content height would exceed appflowy editor compatible scrolling height
      disableAutoScroll: !needsScrolling,
      editorState: textEditorState,
      scrollController: scrollController,
      editorPadding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      onChanged: (body, html) {
        final isTyping = html != null ? html.isNotEmpty : body.isNotEmpty;
        widget.onTyping?.call(isTyping);
      },
    );
  }

  // attachment/send button
  Widget trailingBtn() {
    final allowEditing = ref.watch(allowSendInputProvider(widget.roomId));
    return ValueListenableBuilder<bool>(
      valueListenable: _isInputEmptyNotifier,
      builder: (context, isEmpty, child) {
        if (allowEditing && !isEmpty) {
          return _renderSendBtn();
        }
        return _renderAttachmentBtn();
      },
    );
  }

  Widget _renderSendBtn() => Padding(
    padding: const EdgeInsets.only(right: 12, top: 12),
    child: IconButton.filled(
      alignment: Alignment.center,
      key: ChatEditor.sendBtnKey,
      iconSize: 20,
      onPressed:
          () => sendMessageAction(
            textEditorState: textEditorState,
            roomId: widget.roomId,
            onTyping: widget.onTyping,
            context: context,
            ref: ref,
            log: _log,
          ),
      icon: const Icon(Icons.send),
    ),
  );

  Widget _renderAttachmentBtn() => Padding(
    padding: const EdgeInsets.only(right: 12, top: 12),
    child: IconButton(
      onPressed:
          () => selectAttachment(
            context: context,
            onSelected:
                (files, type) => attachmentUploadAction(
                  roomId: widget.roomId,
                  files: files,
                  attachmentType: type,
                  ref: ref,
                  context: context,
                  log: _log,
                ),
          ),
      icon: const Icon(Atlas.paperclip_attachment_thin, size: 20),
    ),
  );
}
