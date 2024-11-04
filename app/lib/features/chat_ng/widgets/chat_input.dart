import 'dart:async';
import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgDraft;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/common/extensions/options.dart';

final _log = Logger('a3::chat::custom_input');

final _allowEdit = StateProvider.family.autoDispose<bool, String>(
  (ref, roomId) => ref.watch(
    chatInputProvider
        .select((state) => state.sendingState == SendingState.preparing),
  ),
);

class ChatInput extends ConsumerWidget {
  static const loadingKey = Key('chat-ng-loading');
  static const noAccessKey = Key('chat-ng-no-access');

  final String roomId;
  final void Function(bool)? onTyping;

  const ChatInput({super.key, required this.roomId, this.onTyping});

  Widget _loadingWidget(BuildContext context) {
    return Skeletonizer(
      child: FrostEffect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions, size: 20),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: IntrinsicHeight(
                      child: HtmlEditor(
                        footer: null,
                        editable: true,
                        shrinkWrap: true,
                        editorPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        onChanged: (body, html) {},
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Atlas.paperclip_attachment_thin,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noAccessWidget(BuildContext context) {
    return FrostEffect(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const SizedBox(width: 1),
              const Icon(
                Atlas.block_prohibited_thin,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                key: ChatInput.noAccessKey,
                L10n.of(context).chatMissingPermissionsToSend,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(canSendProvider(roomId)).valueOrNull;
    if (canSend == null) {
      // we are still loading
      return _loadingWidget(context);
    }
    if (canSend) {
      return _InputWidget(
        roomId: roomId,
        onTyping: onTyping,
      );
    }
    // no permissions to send messages
    return _noAccessWidget(context);
  }
}

class _InputWidget extends ConsumerStatefulWidget {
  final String roomId;
  final void Function(bool)? onTyping;
  const _InputWidget({required this.roomId, this.onTyping});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __InputWidgetState();
}

class __InputWidgetState extends ConsumerState<_InputWidget> {
  EditorState textEditorState = EditorState.blank();
  late EditorScrollController scrollController;
  FocusNode chatFocus = FocusNode();
  StreamSubscription<(TransactionTime, Transaction)>? _updateListener;
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);
  double _cHeight = 0.10;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    scrollController =
        EditorScrollController(editorState: textEditorState, shrinkWrap: true);
    _updateListener?.cancel();
    // listener for editor input state
    _updateListener = textEditorState.transactionStream.listen((data) {
      _inputUpdate();
      // expand when user types more than one line upto exceed limit
      _updateHeight();
    });
    // have it call the first time to adjust height
    _updateHeight();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft);
  }

  @override
  void dispose() {
    _updateListener?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
    }
  }

  void _inputUpdate() {
    // check if actual document content is empty
    final state = textEditorState.document.root.children
        .every((node) => node.delta?.toPlainText().isEmpty ?? true);
    _isInputEmptyNotifier.value = state;
    _debounceTimer?.cancel();
    // delay operation to avoid excessive re-writes
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // save composing draft
      await saveDraft(textEditorState.intoMarkdown(), widget.roomId, ref);
      _log.info('compose draft saved for room: ${widget.roomId}');
    });
  }

  // handler for expanding editor field height
  void _updateHeight() {
    final text = textEditorState.intoMarkdown();
    final lineCount = '\n'.allMatches(text).length;

    // Calculate new height based on line count
    // Start with 5% and increase by 4% per line up to 20%
    setState(() {
      _cHeight = (0.05 + (lineCount - 1) * 0.04).clamp(0.05, 0.15);
    });
  }

  // composer draft load state handler
  Future<void> _loadDraft() async {
    final draft =
        await ref.read(chatComposerDraftProvider(widget.roomId).future);

    if (draft != null) {
      final inputNotifier = ref.read(chatInputProvider.notifier);
      inputNotifier.unsetSelectedMessage();
      draft.eventId().map((eventId) {
        final draftType = draft.draftType();
        final m = ref
            .read(chatMessagesProvider(widget.roomId))
            .firstWhere((x) => x.id == eventId);
        if (draftType == 'edit') {
          inputNotifier.setEditMessage(m);
        } else if (draftType == 'reply') {
          inputNotifier.setReplyToMessage(m);
        }
      });
      await draft.htmlText().mapAsync(
        (html) async {
          final doc = ActerDocumentHelpers.parse(
            draft.plainText(),
            htmlContent: draft.htmlText(),
          );
          final transaction = textEditorState.transaction;
          transaction.insertNodes([0], doc.root.children);

          textEditorState.apply(transaction);
        },
        orElse: () {
          final doc = ActerDocumentHelpers.parse(
            draft.plainText(),
          );
          final transaction = textEditorState.transaction;
          transaction.insertNodes([0], doc.root.children);
          textEditorState.apply(transaction);
        },
      );
      _log.info('compose draft loaded for room: ${widget.roomId}');
    }
  }

  Future<void> onSendButtonPressed(String body, String? html) async {
    final lang = L10n.of(context);
    ref.read(chatInputProvider.notifier).startSending();

    try {
      // end the typing notification
      widget.onTyping?.map((cb) => cb(false));

      // make the actual draft
      final client = ref.read(alwaysClientProvider);
      late MsgDraft draft;
      if (html != null) {
        draft = client.textHtmlDraft(html, body);
      } else {
        draft = client.textMarkdownDraft(body);
      }

      // actually send it out
      final inputState = ref.read(chatInputProvider);
      final stream =
          await ref.read(timelineStreamProvider(widget.roomId).future);

      if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
        final remoteId = inputState.selectedMessage?.remoteId;
        if (remoteId == null) throw 'remote id of sel msg not available';
        await stream.replyMessage(remoteId, draft);
      } else if (inputState.selectedMessageState == SelectedMessageState.edit) {
        final remoteId = inputState.selectedMessage?.remoteId;
        if (remoteId == null) throw 'remote id of sel msg not available';
        await stream.editMessage(remoteId, draft);
      } else {
        await stream.sendMessage(draft);
      }

      ref.read(chatInputProvider.notifier).messageSent();
      final transaction = textEditorState.transaction;
      final nodes = transaction.document.root.children;
      // delete all nodes of document (reset)
      transaction.document.delete([0], nodes.length);
      final delta = Delta()..insert('');
      // insert empty text node
      transaction.document.insert([0], [paragraphNode(delta: delta)]);
      await textEditorState.apply(transaction, withUpdateSelection: false);
      // FIXME: works for single text, but doesn't get focus on multi-line
      textEditorState.moveCursorForward(SelectionMoveRange.line);

      // also clear composed state
      final convo = await ref.read(chatProvider(widget.roomId).future);
      if (convo != null) {
        await convo.saveMsgDraft(
          textEditorState.intoMarkdown(),
          null,
          'new',
          null,
        );
      }
    } catch (e, s) {
      _log.severe('Sending chat message failed', e, s);
      EasyLoading.showError(
        lang.failedToSend(e),
        duration: const Duration(seconds: 3),
      );
      ref.read(chatInputProvider.notifier).sendingFailed();
    }

    if (!chatFocus.hasFocus) {
      chatFocus.requestFocus();
    }
  }

  // UI handler for emoji picker widget
  void onEmojiBtnTap(bool emojiPickerVisible) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    if (!emojiPickerVisible) {
      //Hide soft keyboard and then show Emoji Picker
      chatInputNotifier.emojiPickerVisible(true);
    } else {
      //Hide Emoji Picker
      chatInputNotifier.emojiPickerVisible(false);
    }
  }

  void handleEmojiSelected(Category? category, Emoji emoji) {
    final selection = textEditorState.selection;
    final transaction = textEditorState.transaction;
    if (selection != null) {
      if (selection.isCollapsed) {
        final node = textEditorState.getNodeAtPath(selection.end.path);
        if (node == null) return;
        // we're at the start
        transaction.insertText(node, selection.endIndex, emoji.emoji);
        transaction.afterSelection = Selection.collapsed(
          Position(
            path: selection.end.path,
            offset: selection.end.offset + emoji.emoji.length,
          ),
        );
      } else {
        // we have selected some text part to replace with emoji
        final startNode = textEditorState.getNodeAtPath(selection.start.path);
        if (startNode == null) return;
        transaction.deleteText(
          startNode,
          selection.startIndex,
          selection.end.offset - selection.start.offset,
        );
        transaction.insertText(
          startNode,
          selection.startIndex,
          emoji.emoji,
        );

        transaction.afterSelection = Selection.collapsed(
          Position(
            path: selection.start.path,
            offset: selection.start.offset + emoji.emoji.length,
          ),
        );
      }

      textEditorState.apply(transaction);
    }
    return;
  }

  // editor picker widget backspace handling
  void handleBackspacePressed() {
    final isEmpty = textEditorState.transaction.document.isEmpty;
    if (isEmpty) {
      // nothing left to clear, close the emoji picker
      ref.read(chatInputProvider.notifier).emojiPickerVisible(false);
      return;
    }
    textEditorState.deleteBackward();
  }

  // attachment upload handler
  Future<void> handleFileUpload(
    List<File> files,
    AttachmentType attachmentType,
  ) async {
    final client = ref.read(alwaysClientProvider);
    final inputState = ref.read(chatInputProvider);
    final lang = L10n.of(context);
    final stream = await ref.read(timelineStreamProvider(widget.roomId).future);

    try {
      for (final file in files) {
        String? mimeType = lookupMimeType(file.path);
        if (mimeType == null) throw lang.failedToDetectMimeType;
        final fileLen = file.lengthSync();
        if (mimeType.startsWith('image/') &&
            attachmentType == AttachmentType.image) {
          final bytes = file.readAsBytesSync();
          final image = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(fileLen)
              .width(image.width)
              .height(image.height);
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            final remoteId = inputState.selectedMessage?.remoteId;
            if (remoteId == null) throw 'remote id of sel msg not available';
            await stream.replyMessage(remoteId, imageDraft);
          } else {
            await stream.sendMessage(imageDraft);
          }
        } else if (mimeType.startsWith('audio/') &&
            attachmentType == AttachmentType.audio) {
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            final remoteId = inputState.selectedMessage?.remoteId;
            if (remoteId == null) throw 'remote id of sel msg not available';
            await stream.replyMessage(remoteId, audioDraft);
          } else {
            await stream.sendMessage(audioDraft);
          }
        } else if (mimeType.startsWith('video/') &&
            attachmentType == AttachmentType.video) {
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            final remoteId = inputState.selectedMessage?.remoteId;
            if (remoteId == null) throw 'remote id of sel msg not available';
            await stream.replyMessage(remoteId, videoDraft);
          } else {
            await stream.sendMessage(videoDraft);
          }
        } else {
          final fileDraft =
              client.fileDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            final remoteId = inputState.selectedMessage?.remoteId;
            if (remoteId == null) throw 'remote id of sel msg not available';
            await stream.replyMessage(remoteId, fileDraft);
          } else {
            await stream.sendMessage(fileDraft);
          }
        }
      }
    } catch (e, s) {
      _log.severe('error occurred', e, s);
    }

    ref.read(chatInputProvider.notifier).unsetSelectedMessage();
  }

  Widget _editorWidget(bool emojiPickerVisible) {
    final widgetSize = MediaQuery.sizeOf(context);
    return FrostEffect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Row(
          children: [
            leadingButton(emojiPickerVisible),
            IntrinsicHeight(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: widgetSize.height * _cHeight,
                width: widgetSize.width * 0.75,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).unselectedWidgetColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: IntrinsicHeight(
                    child: Focus(
                      focusNode: chatFocus,
                      child: HtmlEditor(
                        footer: null,
                        roomId: widget.roomId,
                        editable: true,
                        shrinkWrap: true,
                        editorState: textEditorState,
                        scrollController: scrollController,
                        editorPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        onChanged: (body, html) {
                          if (html != null) {
                            widget.onTyping?.map((cb) => cb(html.isNotEmpty));
                          } else {
                            widget.onTyping?.map((cb) => cb(body.isNotEmpty));
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isInputEmptyNotifier,
              builder: (context, isEmpty, child) =>
                  trailingButton(context, widget.roomId, isEmpty),
            ),
          ],
        ),
      ),
    );
  }

  // emoji button
  Widget leadingButton(bool emojiPickerVisible) {
    return IconButton(
      onPressed: () => onEmojiBtnTap(emojiPickerVisible),
      icon: const Icon(Icons.emoji_emotions, size: 20),
    );
  }

  // attachment/send button
  Widget trailingButton(BuildContext context, String roomId, bool isEmpty) {
    final allowEditing = ref.watch(_allowEdit(roomId));
    final body = textEditorState.intoMarkdown();
    final html = textEditorState.intoHtml();
    if (allowEditing && !isEmpty) {
      return IconButton.filled(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        key: CustomChatInput.sendBtnKey,
        iconSize: 20,
        onPressed: () => onSendButtonPressed(body, html),
        icon: const Icon(Icons.send),
      );
    }

    return IconButton(
      onPressed: () => selectAttachment(
        context: context,
        onSelected: handleFileUpload,
      ),
      icon: const Icon(
        Atlas.paperclip_attachment_thin,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = ref.watch(keyboardVisibleProvider).valueOrNull;
    final emojiPickerVisible = ref
        .watch(chatInputProvider.select((value) => value.emojiPickerVisible));
    final screenSize = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Column(
      children: <Widget>[
        _editorWidget(emojiPickerVisible),
        if (emojiPickerVisible)
          EmojiPickerWidget(
            size: Size(screenSize.width, screenSize.height / 3),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
            onClosePicker: () =>
                ref.read(chatInputProvider.notifier).emojiPickerVisible(false),
          ),
        // adjust bottom viewport so toolbar doesn't obscure field when visible
        if (isKeyboardVisible != null && isKeyboardVisible)
          SizedBox(height: viewInsets + 50),
      ],
    );
  }
}
