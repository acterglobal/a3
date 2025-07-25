import 'dart:async';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/toolkit/html_editor/html_editor.dart';
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
  late EditorState textEditorState;
  StreamSubscription<EditorTransactionValue>? _updateListener;
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    textEditorState.dispose();
    _updateListener?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      // room id changes, dispose the old editor state
      textEditorState.dispose();
      _init();
    }
  }

  void _init() {
    textEditorState = EditorState.blank();
    _updateListener?.cancel();
    // listener for editor input state
    _updateListener = textEditorState.transactionStream.listen((data) {
      _editorUpdate(data.$2);
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
        // set selection of editor for composing
        final t = textEditorState.transaction;
        t.afterSelection = Selection.single(
          path: textEditorState.document.root.children.last.path,
          startOffset:
              textEditorState.document.root.children.last.delta?.length ?? 0,
        );
        textEditorState.apply(t);
        saveMsgDraft(body, bodyHtml, widget.roomId, ref);
      }
    });
  }

  void _handleEditing(TimelineEventItem? item) {
    if (item == null) return;

    final msgContent = item.msgContent();
    if (msgContent == null) return;

    final body = msgContent.body();
    if (body.isEmpty) return;

    textEditorState.replaceContent(body, msgContent.formattedBody());
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

      final htmlBody = draft.htmlText();
      final fallbackPlain = draft.plainText();
      if (fallbackPlain.trim().isNotEmpty) {
        textEditorState.replaceContent(fallbackPlain, htmlBody);
      } else {
        // FOR DESKTOP/SIDE VIEW:
        // it means the draft is empty, but still valid document (e.g. empty paragraph) for editor to get auto focused
        // set selection to null to avoid the editor from being focused
        if (mounted) {
          bool isLargeScreen = MediaQuery.sizeOf(context).width > 600;
          if (isLargeScreen) {
            final t = textEditorState.transaction;
            t.afterSelection = null;
            textEditorState.apply(t);
          }
        }
      }

      _log.info('compose text draft loaded for room: ${widget.roomId}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        renderEditorUI(emojiPickerVisible, isEncrypted),

        // Emoji Picker UI
        if (emojiPickerVisible) ChatEmojiPicker(editorState: textEditorState),
      ],
    );
  }

  // chat editor UI
  Widget renderEditorUI(bool emojiPickerVisible, bool isEncrypted) {
    final chatEditorState = ref.watch(chatEditorStateProvider);
    final isPreviewOpen =
        chatEditorState.isReplying || chatEditorState.isEditing;
    final radiusVal = isPreviewOpen ? 2.0 : 15.0;

    return Container(
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
          Expanded(child: editorField(isEncrypted)),
          trailingBtn(),
        ],
      ),
    );
  }

  void _toggleEmojiPicker(bool emojiPickerVisible) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    chatInputNotifier.emojiPickerVisible(!emojiPickerVisible);
  }

  Widget editorField(bool isEncrypted) {
    final hintText =
        isEncrypted == true
            ? L10n.of(context).newEncryptedMessage
            : L10n.of(context).newMessage;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (isDesktop(context))
          const SingleActivator(LogicalKeyboardKey.enter):
              () => sendMessageAction(
                roomId: widget.roomId,
                textEditorState: textEditorState,
                onTyping: widget.onTyping,
                context: context,
                ref: ref,
                log: _log,
              ),
        if (isDesktop(context))
          LogicalKeySet(LogicalKeyboardKey.enter, LogicalKeyboardKey.shift):
              () => textEditorState.insertNewLine(),
      },
      child: _renderEditor(context, hintText),
    );
  }

  Widget _renderEditor(BuildContext context, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: HtmlEditor(
        footer: null,
        // if provided, will activate mentions
        roomId: widget.roomId,
        hintText: hintText,
        editable: true,
        shrinkWrap: false,
        disableAutoScroll: false,
        editorState: textEditorState,
        maxHeight: MediaQuery.sizeOf(context).height * 0.2,
        minHeight: 24,
        onChanged: (body, html) {
          final isTyping = html != null ? html.isNotEmpty : body.isNotEmpty;
          widget.onTyping?.call(isTyping);
        },
        onSave: null,
      ),
    );
  }

  // emoji button
  Widget leadingBtn(bool emojiPickerVisible) => Padding(
    padding: const EdgeInsets.only(top: 4, left: 4),
    child: IconButton(
      onPressed: () => _toggleEmojiPicker(emojiPickerVisible),
      icon: const Icon(Icons.emoji_emotions, size: 20),
    ),
  );

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
    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
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
    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
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
