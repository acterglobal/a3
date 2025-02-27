import 'dart:async';
import 'dart:io';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/mention_profile_builder.dart';
import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgDraft;
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_matrix_html/text_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::custom_input');

class CustomChatInput extends ConsumerWidget {
  static const noAccessKey = Key('custom-chat-no-access');
  static const loadingKey = Key('custom-chat-loading');
  static const sendBtnKey = Key('custom-chat-send-button');

  final String roomId;
  final void Function(bool)? onTyping;

  const CustomChatInput({required this.roomId, this.onTyping, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(canSendMessageProvider(roomId)).valueOrNull;
    final unselectedWidgetColor = Theme.of(context).unselectedWidgetColor;
    if (canSend == null) {
      // we are still loading
      return loadingState(context);
    }
    if (canSend) {
      return _ChatInput(roomId: roomId, onTyping: onTyping);
    }

    return FrostEffect(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const SizedBox(width: 1),
              Icon(
                Atlas.block_prohibited_thin,
                size: 14,
                color: unselectedWidgetColor,
              ),
              const SizedBox(width: 4),
              Text(
                key: noAccessKey,
                L10n.of(context).chatMissingPermissionsToSend,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: unselectedWidgetColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget loadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Skeletonizer(
      child: FrostEffect(
        child: Container(
          key: loadingKey,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(color: colorScheme.surface),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Atlas.paperclip_attachment_thin, size: 20),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      style: textTheme.bodyMedium,
                      cursorColor: colorScheme.primary,
                      maxLines: 6,
                      minLines: 1,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        prefixIcon: Icon(
                          Icons.shield,
                          size: 18,
                          color: colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        suffixIcon: const Icon(Icons.emoji_emotions),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            width: 0.5,
                            style: BorderStyle.solid,
                            color: colorScheme.surface,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            width: 0.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            width: 0.5,
                            style: BorderStyle.solid,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        hintText: L10n.of(context).newMessage,
                        hintStyle: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        contentPadding: const EdgeInsets.all(15),
                        hintMaxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends ConsumerStatefulWidget {
  final String roomId;
  final void Function(bool)? onTyping;

  const _ChatInput({required this.roomId, this.onTyping});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __ChatInputState();
}

class __ChatInputState extends ConsumerState<_ChatInput> {
  late final ActerTriggerAutoCompleteTextController textController;
  final FocusNode chatFocus = FocusNode();
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _setController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDraft();
    });
  }

  @override
  void didUpdateWidget(covariant _ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadDraft();
      });
    }
  }

  void _setController() {
    // putting constant colors here as context isn’t accessible in initState()
    final triggerStyles = {
      '@': TextStyle(
        color: Colors.white,
        height: 0.5,
        background:
            Paint()
              ..color = const Color(0xFF74A64D)
              ..strokeWidth = 10
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke,
      ),
    };
    textController = ActerTriggerAutoCompleteTextController(
      triggerStyles: triggerStyles,
    );
    textController.addListener(_updateInputState);
  }

  // composer draft load state handler
  Future<void> loadDraft() async {
    final draft = await ref.read(
      chatComposerDraftProvider(widget.roomId).future,
    );

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
          await parseUserMentionText(html, widget.roomId, textController, ref);
        },
        orElse: () {
          textController.text = draft.plainText();
        },
      );

      _log.info('compose draft loaded for room: ${widget.roomId}');
    }
  }

  // listener for handling send state
  void _updateInputState() {
    _isInputEmptyNotifier.value = textController.text.trim().isEmpty;
    _debounceTimer?.cancel();
    // delay operation to avoid excessive re-writes
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // save composing draft
      await saveDraft(textController.text, null, widget.roomId, ref);
      _log.info('compose draft saved for room: ${widget.roomId}');
    });
  }

  void handleEmojiSelected(Category? category, Emoji emoji) {
    String suffixText = '';

    // Get the left text of cursor
    String prefixText = '';
    // Get cursor current position
    var cursorPos = textController.selection.base.offset;
    int emojiLength = emoji.emoji.length;

    if (cursorPos >= 0) {
      // can be -1 on empty and never accessed

      // Right text of cursor position
      suffixText = textController.text.substring(cursorPos);

      // Get the left text of cursor
      prefixText = textController.text.substring(0, cursorPos);
      textController.text = prefixText + emoji.emoji + suffixText;
    } else {
      // no focus yet, add the emoji at the end of the content
      cursorPos = textController.text.length;
      textController.text += emoji.emoji;
    }

    // Add emoji at current current cursor position

    // Cursor move to end of added emoji character
    textController.selection = TextSelection(
      baseOffset: cursorPos + emojiLength,
      extentOffset: cursorPos + emojiLength,
    );

    // Ensure we keep the cursor up
    // frame delay to keep focus connected with keyboard.
    if (!chatFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatFocus.requestFocus();
      });
    }
  }

  void handleBackspacePressed() {
    if (textController.text.isEmpty) {
      // nothing left to clear, close the emoji picker
      ref.read(chatInputProvider.notifier).emojiPickerVisible(false);
      return;
    }
    final newValue = textController.text.characters.skipLast(1).string;
    textController.text = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMessage = ref.watch(
      chatInputProvider.select((value) => value.selectedMessage),
    );
    if (selectedMessage == null) return renderMain(context);
    final selMsgState = ref.watch(
      chatInputProvider.select((value) => value.selectedMessageState),
    );
    return switch (selMsgState) {
      SelectedMessageState.replyTo => renderReplyView(context, selectedMessage),
      SelectedMessageState.edit => renderEditView(context, selectedMessage),
      SelectedMessageState.none ||
      SelectedMessageState.actions => renderMain(context),
    };
  }

  Widget renderMain(BuildContext context) {
    return renderChatInputArea(context, null);
  }

  Widget renderChatInputArea(BuildContext context, Widget? child) {
    final roomId = widget.roomId;
    final isEncrypted = ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull;
    final emojiPickerVisible = ref.watch(
      chatInputProvider.select((value) => value.emojiPickerVisible),
    );
    final screenSize = MediaQuery.of(context).size;
    return Column(
      children: [
        if (child != null) child,
        FrostEffect(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(
                    child: _TextInputWidget(
                      roomId: roomId,
                      controller: textController,
                      chatFocus: chatFocus,
                      onSendButtonPressed: () => onSendButtonPressed(ref),
                      isEncrypted: isEncrypted == true,
                      onTyping: widget.onTyping,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isInputEmptyNotifier,
                    builder: (context, isEmpty, child) {
                      return !isEmpty
                          ? renderSendButton(context, roomId)
                          : renderAttachmentPinButton();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (emojiPickerVisible)
          EmojiPickerWidget(
            size: Size(screenSize.width, screenSize.height / 3),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
            onClosePicker:
                () => ref
                    .read(chatInputProvider.notifier)
                    .emojiPickerVisible(false),
          ),
      ],
    );
  }

  Widget renderAttachmentPinButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap:
            () => selectAttachment(
              context: context,
              onSelected: handleFileUpload,
            ),
        child: const Icon(Atlas.paperclip_attachment_thin, size: 20),
      ),
    );
  }

  Widget renderSendButton(BuildContext context, String roomId) {
    final allowEditing = ref.watch(allowSendInputProvider(roomId));

    if (allowEditing) {
      return IconButton.filled(
        key: CustomChatInput.sendBtnKey,
        iconSize: 20,
        onPressed: () => onSendButtonPressed(ref),
        icon: const Icon(Icons.send),
      );
    }

    return IconButton.filled(
      iconSize: 20,
      onPressed: () => {},
      icon: Icon(
        Icons.send,
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }

  Widget renderReplyView(BuildContext context, Message repliedToMessage) {
    return renderChatInputArea(
      context,
      FrostEffect(
        widgetWidth: MediaQuery.of(context).size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6.0),
              topRight: Radius.circular(6.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder:
                      (context, ref, child) =>
                          replyBuilder(widget.roomId, repliedToMessage),
                ),
                _ReplyContentWidget(
                  roomId: widget.roomId,
                  msg: repliedToMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget renderEditView(BuildContext context, Message editMessage) {
    return renderChatInputArea(
      context,
      FrostEffect(
        widgetWidth: MediaQuery.of(context).size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6.0),
              topRight: Radius.circular(6.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Consumer(builder: editMessageBuilder),
          ),
        ),
      ),
    );
  }

  Future<void> handleFileUpload(
    List<File> files,
    AttachmentType attachmentType,
  ) async {
    final lang = L10n.of(context);
    final client = await ref.read(alwaysClientProvider.future);
    final inputState = ref.read(chatInputProvider);
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
          final audioDraft = client
              .audioDraft(file.path, mimeType)
              .size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            final remoteId = inputState.selectedMessage?.remoteId;
            if (remoteId == null) throw 'remote id of sel msg not available';
            await stream.replyMessage(remoteId, audioDraft);
          } else {
            await stream.sendMessage(audioDraft);
          }
        } else if (mimeType.startsWith('video/') &&
            attachmentType == AttachmentType.video) {
          final videoDraft = client
              .videoDraft(file.path, mimeType)
              .size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            final remoteId = inputState.selectedMessage?.remoteId;
            if (remoteId == null) throw 'remote id of sel msg not available';
            await stream.replyMessage(remoteId, videoDraft);
          } else {
            await stream.sendMessage(videoDraft);
          }
        } else {
          final fileDraft = client
              .fileDraft(file.path, mimeType)
              .size(file.lengthSync());
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

  Widget replyBuilder(String roomId, Message repliedToMessage) {
    final authorId = repliedToMessage.author.id;
    final memberAvatar = ref.watch(
      memberAvatarInfoProvider((userId: authorId, roomId: roomId)),
    );
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(Icons.reply_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        ActerAvatar(options: AvatarOptions.DM(memberAvatar, size: 12)),
        const SizedBox(width: 5),
        Text(
          L10n.of(context).replyTo(toBeginningOfSentenceCase(authorId)),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            inputNotifier.unsetSelectedMessage();
            chatFocus.requestFocus();
          },
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  Widget editMessageBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(Atlas.pencil_edit_thin, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          L10n.of(context).editMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            inputNotifier.unsetSelectedMessage();
            textController.clear();
          },
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed(WidgetRef ref) async {
    if (textController.text.isEmpty) return;
    final lang = L10n.of(context);
    ref.read(chatInputProvider.notifier).startSending();
    try {
      // end the typing notification
      widget.onTyping.map((cb) => cb(false));

      final mentions = ref.read(chatInputProvider).mentions;
      String markdownText = textController.text;
      // Replace empty new lines with <br> tags
      markdownText = markdownText.replaceAll(RegExp(r'(\n\s*\n)'), '\n<br>\n');
      final userMentions = [];
      mentions.forEach((key, value) {
        userMentions.add(value);
        markdownText = markdownText.replaceAll(
          '@$key',
          '[@$key](https://matrix.to/#/$value)',
        );
      });

      // make the actual draft
      final client = await ref.read(alwaysClientProvider.future);
      MsgDraft draft = client.textMarkdownDraft(markdownText);

      for (final userId in userMentions) {
        draft = draft.addMention(userId);
      }

      // actually send it out
      final inputState = ref.read(chatInputProvider);
      final stream = await ref.read(
        timelineStreamProvider(widget.roomId).future,
      );

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

      textController.clear();
      // also clear composed state
      final convo = await ref.read(chatProvider(widget.roomId).future);
      if (convo != null) {
        await convo.saveMsgDraft(textController.text, null, 'new', null);
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
}

class _TextInputWidget extends ConsumerStatefulWidget {
  final String roomId;
  final ActerTriggerAutoCompleteTextController controller;
  final FocusNode chatFocus;
  final Function() onSendButtonPressed;
  final bool isEncrypted;
  final void Function(bool)? onTyping;

  const _TextInputWidget({
    required this.roomId,
    required this.controller,
    required this.chatFocus,
    required this.onSendButtonPressed,
    this.onTyping,
    this.isEncrypted = false,
  });

  @override
  ConsumerState<_TextInputWidget> createState() =>
      _TextInputWidgetConsumerState();
}

class _TextInputWidgetConsumerState extends ConsumerState<_TextInputWidget> {
  EditorState textEditorState = EditorState.blank(withInitialText: true);

  @override
  void initState() {
    super.initState();
    ref.listenManual(chatInputProvider, (prev, next) {
      if (next.selectedMessageState == SelectedMessageState.edit &&
          (prev?.selectedMessageState != next.selectedMessageState ||
              next.selectedMessage != prev?.selectedMessage)) {
        // a new message has been selected to be edited or switched from reply
        // to edit, force refresh the inner text controller to reflect that
        next.selectedMessage.map((selected) {
          widget.controller.text = parseEditMsg(selected);
          // frame delay to keep focus connected with keyboard.
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.chatFocus.requestFocus();
        });
      } else if (next.selectedMessageState == SelectedMessageState.replyTo &&
          (next.selectedMessage != prev?.selectedMessage ||
              prev?.selectedMessageState != next.selectedMessageState)) {
        // controller doesn’t update text so manually save draft state
        saveDraft(widget.controller.text, null, widget.roomId, ref);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.chatFocus.requestFocus();
        });
      }
    });
  }

  void onTextTap(bool emojiPickerVisible, WidgetRef ref) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);

    ///Hide emoji picker before input field get focus if
    ///Platform is mobile & Emoji picker is visible
    if (!isDesktop && emojiPickerVisible) {
      chatInputNotifier.emojiPickerVisible(false);
    }
  }

  void onSuffixTap(
    bool emojiPickerVisible,
    BuildContext context,
    WidgetRef ref,
  ) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    if (!emojiPickerVisible) {
      //Hide soft keyboard and then show Emoji Picker
      chatInputNotifier.emojiPickerVisible(true);
    } else {
      //Hide Emoji Picker
      chatInputNotifier.emojiPickerVisible(false);
    }
  }

  // adds new line
  void _insertNewLine() {
    final TextSelection selection = widget.controller.selection;
    if (selection.isValid) {
      final String text = widget.controller.text;
      final int start = selection.start;
      final newText = text.replaceRange(start, selection.end, '\n');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          widget.onSendButtonPressed();
        },
        LogicalKeySet(LogicalKeyboardKey.enter, LogicalKeyboardKey.shift): () {
          _insertNewLine();
        },
      },
      child: MultiTriggerAutocomplete(
        optionsAlignment: OptionsAlignment.top,
        textEditingController: widget.controller,
        focusNode: widget.chatFocus,
        autocompleteTriggers: [
          AutocompleteTrigger(
            trigger: '@',
            optionsViewBuilder: (context, autocompleteQuery, ctrl) {
              return MentionProfileBuilder(
                context: context,
                roomQuery: (
                  query: autocompleteQuery.query,
                  roomId: widget.roomId,
                ),
              );
            },
          ),
        ],
        fieldViewBuilder: _innerTextField,
      ),
    );
  }

  Widget _innerTextField(
    BuildContext context,
    TextEditingController ctrl,
    FocusNode chatFocus,
  ) {
    final lang = L10n.of(context);
    final screenSize = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      constraints: BoxConstraints(maxHeight: screenSize.height * 0.2),
      child: TextField(
        maxLines: 5,
        minLines: 1,
        onTap:
            () =>
                onTextTap(ref.read(chatInputProvider).emojiPickerVisible, ref),
        controller: widget.controller,
        focusNode: chatFocus,
        textCapitalization: TextCapitalization.sentences,
        enabled: ref.watch(allowSendInputProvider(widget.roomId)),
        onChanged: (String val) {
          // send typing notice
          widget.onTyping.map((cb) => cb(val.isNotEmpty));
        },
        onSubmitted: (_) => widget.onSendButtonPressed(),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          fillColor: Theme.of(
            context,
          ).unselectedWidgetColor.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.all(15),
          isCollapsed: true,
          prefixIcon: InkWell(
            onTap:
                () => onSuffixTap(
                  ref.read(chatInputProvider).emojiPickerVisible,
                  context,
                  ref,
                ),
            child: const Icon(Icons.emoji_emotions),
          ),
          hintText:
              widget.isEncrypted ? lang.newEncryptedMessage : lang.newMessage,
          hintMaxLines: 1,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 0.5),
            borderRadius: BorderRadius.circular(30),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 0.5),
            borderRadius: BorderRadius.circular(30),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}

class _ReplyContentWidget extends StatelessWidget {
  final String roomId;
  final Message msg;

  const _ReplyContentWidget({required this.roomId, required this.msg});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          roomId: roomId,
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      final textMsg = msg as TextMessage;
      return Container(
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          pillBuilder: ({
            required String identifier,
            required String url,
            OnPillTap? onTap,
          }) {
            return ActerPillBuilder(
              identifier: identifier,
              uri: url,
              roomId: roomId,
            );
          },
          defaultTextStyle: textTheme.bodySmall?.copyWith(
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 3,
        ),
      );
    } else if (msg is FileMessage) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(msg.metadata?['content'], style: textTheme.bodySmall),
      );
    } else if (msg is CustomMessage) {
      return CustomMessageBuilder(
        message: msg as CustomMessage,
        messageWidth: 100,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          L10n.of(context).replyPreviewUnavailable,
          style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
  }
}
