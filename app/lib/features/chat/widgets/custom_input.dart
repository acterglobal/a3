import 'dart:io';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/mention_profile_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:mime/mime.dart';

// keep track of text controller values across rooms.
final _textValuesProvider =
    StateProvider.family<String, String>((ref, roomId) => '');

class CustomChatInput extends ConsumerStatefulWidget {
  final Convo convo;

  const CustomChatInput({required this.convo, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomChatInputState();
}

class _CustomChatInputState extends ConsumerState<CustomChatInput> {
  GlobalKey<FlutterMentionsState> mentionKey =
      GlobalKey<FlutterMentionsState>();
  bool isEncrypted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      getEncryptionStatus();
    });
  }

  void getEncryptionStatus() async {
    isEncrypted = await ref
        .read(isRoomEncryptedProvider(widget.convo.getRoomIdStr()).future);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userId = ref.watch(clientProvider)!.userId().toString();
    final roomId = widget.convo.getRoomIdStr();
    final chatInputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    final chatInputState = ref.watch(chatInputProvider(roomId));
    final chatState = ref.watch(chatStateProvider(widget.convo));
    final repliedToMessage = chatInputState.repliedToMessage;
    final editMessage = chatInputState.editMessage;
    final currentMessageId = chatInputState.currentMessageId;
    final showReplyView = ref.watch(
      chatInputProvider(roomId).select((ci) => ci.showReplyView),
    );
    final showEditView = ref.watch(
      chatInputProvider(roomId).select((ci) => ci.showEditView),
    );

    bool isAuthor() {
      if (currentMessageId != null) {
        final messages = chatState.messages;
        int index = messages.indexWhere((x) => x.id == currentMessageId);
        if (index != -1) {
          return userId == messages[index].author.id;
        }
      }
      return false;
    }

    void handleEmojiSelected(Category? category, Emoji emoji) {
      final mentionState = mentionKey.currentState!;
      mentionState.controller!.text += emoji.emoji;
      ref.read(chatInputProvider(roomId).notifier).showSendBtn(true);
    }

    void handleBackspacePressed() {
      final newValue = mentionKey.currentState!.controller!.text.characters
          .skipLast(1)
          .string;
      mentionKey.currentState!.controller!.text = newValue;
      if (newValue.isEmpty) {
        ref.read(chatInputProvider(roomId).notifier).showSendBtn(false);
      }
    }

    return Column(
      children: [
        Visibility(
          visible: showReplyView,
          child: FrostEffect(
            widgetWidth: size.width,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    repliedToMessage != null
                        ? Consumer(builder: replyBuilder)
                        : const SizedBox.shrink(),
                    if (repliedToMessage != null &&
                        chatInputState.replyWidget != null)
                      _ReplyContentWidget(
                        convo: widget.convo,
                        msg: repliedToMessage,
                        messageWidget: chatInputState.replyWidget!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: showEditView,
          child: FrostEffect(
            widgetWidth: size.width,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    editMessage != null
                        ? Consumer(builder: editMessageBuilder)
                        : const SizedBox.shrink(),
                    if (editMessage != null)
                      _EditMessageContentWidget(
                        convo: widget.convo,
                        msg: editMessage,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: !chatInputState.emojiRowVisible,
          replacement: FrostEffect(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (isAuthor()) {
                        showAdaptiveDialog(
                          context: context,
                          builder: (context) => DefaultDialog(
                            title: const Text(
                              'Are you sure you want to delete this message? This action cannot be undone.',
                            ),
                            actions: <Widget>[
                              DefaultButton(
                                onPressed: () => Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(),
                                title: 'No',
                                isOutlined: true,
                              ),
                              DefaultButton(
                                onPressed: () async {
                                  if (currentMessageId != null) {
                                    try {
                                      redactRoomMessage(currentMessageId);
                                      chatInputNotifier.emojiRowVisible(false);
                                      chatInputNotifier
                                          .setCurrentMessageId(null);
                                      if (context.mounted) {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop();
                                      }
                                    } catch (e) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      customMsgSnackbar(
                                        context,
                                        e.toString(),
                                      );
                                    }
                                  } else {
                                    debugPrint(currentMessageId);
                                  }
                                },
                                title: 'Yes',
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.onError,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final message = ref
                            .read(chatStateProvider(widget.convo))
                            .messages
                            .firstWhere(
                              (element) => element.id == currentMessageId,
                            );
                        showAdaptiveDialog(
                          context: context,
                          builder: (context) => ReportContentWidget(
                            title: 'Report this message',
                            description:
                                'Report this message to your homeserver administrator. Please note that adminstrator wouldn\'t be able to read or view any files, if room is encrypted',
                            senderId: message.author.id,
                            roomId: roomId,
                            eventId: currentMessageId!,
                          ),
                        );
                      }
                    },
                    child: Text(
                      isAuthor() ? 'Delete' : 'Report',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final emojiRowVisible = ref.read(
                        chatInputProvider(roomId).select((ci) {
                          return ci.emojiRowVisible;
                        }),
                      );
                      final inputNotifier =
                          ref.read(chatInputProvider(roomId).notifier);
                      if (emojiRowVisible) {
                        inputNotifier.setCurrentMessageId(null);
                        inputNotifier.emojiRowVisible(false);
                      }

                      inputNotifier.toggleEditView(true);
                      final message = ref
                          .read(chatStateProvider(widget.convo))
                          .messages
                          .firstWhere(
                            (element) => element.id == currentMessageId,
                          );
                      chatInputNotifier.setEditMessage(message);
                      var mentionState = mentionKey.currentState;
                      if (message is TextMessage && mentionState != null) {
                        mentionState.controller!.text = message.text;
                      }

                      final chatInputFocusState =
                          ref.watch(chatInputFocusProvider.notifier);
                      FocusScope.of(context)
                          .requestFocus(chatInputFocusState.state);
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  InkWell(
                    onTap: () => customMsgSnackbar(
                      context,
                      'More options not implemented yet',
                    ),
                    child: const Text(
                      'More',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: FrostEffect(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => handleAttachment(ref, context),
                        child: const Icon(
                          Atlas.paperclip_attachment_thin,
                          size: 20,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _TextInputWidget(
                          mentionKey: mentionKey,
                          convo: widget.convo,
                          onSendButtonPressed: onSendButtonPressed,
                          isEncrypted: isEncrypted,
                        ),
                      ),
                    ),
                    if (chatInputState.sendBtnVisible)
                      InkWell(
                        onTap: () => onSendButtonPressed(),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.send,
                            size: 20,
                            color: Theme.of(context).colorScheme.neutral2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: ref.watch(chatInputProvider(roomId)).emojiPickerVisible,
          child: EmojiPickerWidget(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2,
            ),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
          ),
        ),
      ],
    );
  }

// delete message event
  Future<void> redactRoomMessage(String eventId) async {
    await widget.convo.redactMessage(eventId, '', null);
  }

  // file selection
  Future<List<File>?> handleFileSelection(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return null;
  }

  void handleAttachment(WidgetRef ref, BuildContext ctx) async {
    var selectedFiles = await handleFileSelection(ctx);

    if (ctx.mounted) {
      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        String fileName = selectedFiles.first.path.split('/').last;
        final mimeType = lookupMimeType(selectedFiles.first.path);
        showAdaptiveDialog(
          context: ctx,
          builder: (ctx) => DefaultDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Upload Files (${selectedFiles.length})',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            subtitle: Visibility(
              visible: selectedFiles.length <= 5,
              child: _FileWidget(mimeType, selectedFiles.first),
            ),
            description: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(fileName, style: Theme.of(ctx).textTheme.bodySmall),
            ),
            actions: <Widget>[
              DefaultButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                title: 'Cancel',
                isOutlined: true,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(ctx).colorScheme.errorContainer,
                  ),
                ),
              ),
              DefaultButton(
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await handleFileUpload(selectedFiles);
                },
                title: 'Upload',
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.success,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> handleFileUpload(List<File> files) async {
    final roomId = widget.convo.getRoomIdStr();
    final chatInputState = ref.read(chatInputProvider(roomId));
    final chatInputNotifier = ref.read(chatInputProvider(roomId).notifier);
    final convo = widget.convo;

    try {
      for (File file in files) {
        String fileName = file.path.split('/').last;
        String? mimeType = lookupMimeType(file.path);

        if (mimeType!.startsWith('image/')) {
          var bytes = file.readAsBytesSync();
          var image = await decodeImageFromList(bytes);
          if (chatInputState.repliedToMessage != null) {
            await convo.sendImageReply(
              file.path,
              fileName,
              mimeType,
              file.lengthSync(),
              image.width,
              image.height,
              chatInputState.repliedToMessage!.id,
              null,
            );

            chatInputNotifier.setRepliedToMessage(null);
            chatInputNotifier.setEditMessage(null);
            chatInputNotifier.toggleReplyView(false);
            chatInputNotifier.toggleEditView(false);
            chatInputNotifier.setReplyWidget(null);
            chatInputNotifier.setEditWidget(null);
          } else {
            await convo.sendImageMessage(
              file.path,
              fileName,
              mimeType,
              file.lengthSync(),
              image.width,
              image.height,
              null,
            );
          }
        } else if (mimeType.startsWith('/audio')) {
          if (chatInputState.repliedToMessage != null) {
          } else {}
        } else if (mimeType.startsWith('/video')) {
        } else {
          if (chatInputState.repliedToMessage != null) {
            await convo.sendFileReply(
              file.path,
              fileName,
              mimeType,
              file.lengthSync(),
              chatInputState.repliedToMessage!.id,
              null,
            );
            chatInputNotifier.setRepliedToMessage(null);
            chatInputNotifier.setEditMessage(null);
            chatInputNotifier.toggleReplyView(false);
            chatInputNotifier.toggleEditView(false);
            chatInputNotifier.setReplyWidget(null);
            chatInputNotifier.setEditWidget(null);
          } else {
            await convo.sendFileMessage(
              file.path,
              fileName,
              mimeType,
              file.lengthSync(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('error occurred: $e');
    }
  }

  Widget replyBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final roomId = widget.convo.getRoomIdStr();
    final chatInputState = ref.watch(chatInputProvider(roomId));
    final authorId = chatInputState.repliedToMessage!.author.id;
    final replyProfile = ref.watch(memberProfileByIdProvider(authorId));
    final inputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    return Row(
      children: [
        replyProfile.when(
          data: (profile) => ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: authorId,
            displayName: profile.displayName ?? authorId,
            avatar: profile.getAvatarImage(),
            size: profile.hasAvatar() ? 12 : 24,
          ),
          error: (e, st) {
            debugPrint('Error loading avatar due to $e');
            return ActerAvatar(
              mode: DisplayMode.User,
              uniqueId: authorId,
              displayName: authorId,
              size: 24,
            );
          },
          loading: () => const CircularProgressIndicator(),
        ),
        const SizedBox(width: 5),
        Text(
          'Reply to ${toBeginningOfSentenceCase(authorId)}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            inputNotifier.toggleReplyView(false);
            inputNotifier.toggleEditView(false);
            inputNotifier.setReplyWidget(null);
            inputNotifier.setEditWidget(null);
            inputNotifier.setRepliedToMessage(null);
            inputNotifier.setEditMessage(null);
            FocusScope.of(context).unfocus();
          },
          child: const Icon(
            Atlas.xmark_circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget editMessageBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final roomId = widget.convo.getRoomIdStr();
    final inputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    return Row(
      children: [
        const SizedBox(width: 5),
        const Text(
          'Edit:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            inputNotifier.toggleReplyView(false);
            inputNotifier.toggleEditView(false);
            inputNotifier.setReplyWidget(null);
            inputNotifier.setEditWidget(null);
            inputNotifier.setRepliedToMessage(null);
            inputNotifier.setEditMessage(null);
            FocusScope.of(context).unfocus();
          },
          child: const Icon(
            Atlas.xmark_circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed() async {
    if (mentionKey.currentState!.controller!.text.isEmpty) return;
    final roomId = widget.convo.getRoomIdStr();
    final inputNotifier = ref.read(chatInputProvider(roomId).notifier);
    final mentionReplacements =
        ref.read(chatInputProvider(roomId)).mentionReplacements;
    final mentionState = mentionKey.currentState!;
    inputNotifier.prepareSending();
    String markdownText = mentionState.controller!.text;
    int messageLength = markdownText.length;
    mentionReplacements.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });

    try {
      await handleSendPressed(markdownText, messageLength);
      inputNotifier.messageSent();
      mentionState.controller!.clear();
    } catch (e) {
      if (context.mounted) {
        customMsgSnackbar(context, 'Error sending message: $e');
      }
      inputNotifier.sendingFailed();
    }
  }

  // push messages in convo
  Future<void> handleSendPressed(
    String markdownMessage,
    int messageLength,
  ) async {
    final convo = widget.convo;
    final roomId = widget.convo.getRoomIdStr();
    final chatInputState = ref.watch(chatInputProvider(roomId));
    final chatInputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    // image or video is sent automatically
    // user will click "send" button explicitly for text only
    await convo.typingNotice(false);
    if (chatInputState.repliedToMessage != null) {
      await convo.sendTextReply(
        markdownMessage,
        chatInputState.repliedToMessage!.id,
        null,
      );
      chatInputNotifier.setRepliedToMessage(null);
      chatInputNotifier.setEditMessage(null);
      final inputNotifier = ref.read(chatInputProvider(roomId).notifier);
      inputNotifier.toggleReplyView(false);
      inputNotifier.toggleEditView(false);
      inputNotifier.setReplyWidget(null);
      inputNotifier.setEditWidget(null);
    } else if (chatInputState.editMessage != null) {
      await convo.editFormattedMessage(
        chatInputState.editMessage!.id,
        markdownMessage,
      );
      chatInputNotifier.setRepliedToMessage(null);
      chatInputNotifier.setEditMessage(null);
      final inputNotifier = ref.read(chatInputProvider(roomId).notifier);
      inputNotifier.toggleReplyView(false);
      inputNotifier.toggleEditView(false);
      inputNotifier.setReplyWidget(null);
      inputNotifier.setEditWidget(null);
    } else {
      await convo.sendFormattedMessage(markdownMessage);
    }
  }
}

class _FileWidget extends ConsumerWidget {
  const _FileWidget(this.mimeType, this.file);

  final String? mimeType;
  final File file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mimeType!.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(file, height: 200, fit: BoxFit.cover),
      );
    } else if (mimeType!.startsWith('audio/')) {
      return Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Atlas.file_sound_thin)),
      );
    } else if (mimeType!.startsWith('video/')) {
      return Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Atlas.file_video_thin)),
      );
    }
    //FIXME: cover all mime extension cases?
    else {
      return Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Atlas.plus_file_thin)),
      );
    }
  }
}

class _TextInputWidget extends ConsumerWidget {
  final GlobalKey<FlutterMentionsState> mentionKey;
  final Convo convo;
  final Function() onSendButtonPressed;
  final bool isEncrypted;

  const _TextInputWidget({
    required this.mentionKey,
    required this.convo,
    required this.onSendButtonPressed,
    this.isEncrypted = false,
  });

  void _updateTextValue(String roomId, WidgetRef ref) {
    String textValue = '';
    textValue += mentionKey.currentState!.controller!.text;
    ref.read(_textValuesProvider(roomId).notifier).update((state) => textValue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = convo.getRoomIdStr();
    final chatInputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    final chatInputState = ref.watch(chatInputProvider(roomId));
    final width = MediaQuery.of(context).size.width;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          onSendButtonPressed();
        },
      },
      child: Focus(
        child: FlutterMentions(
          key: mentionKey,
          // restore input if available
          defaultText: ref.watch(_textValuesProvider(roomId)),
          suggestionPosition: SuggestionPosition.Top,
          suggestionListWidth: width >= 770 ? width * 0.6 : width * 0.8,
          onMentionAdd: (Map<String, dynamic> roomMember) {
            String authorId = roomMember['link'];
            String displayName = roomMember['display'] ?? authorId;

            ref
                .read(chatInputProvider(roomId).notifier)
                .addMention(displayName, authorId);
          },
          suggestionListDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(6),
          ),
          onChanged: (String value) async {
            _updateTextValue(roomId, ref);
            if (value.isNotEmpty) {
              chatInputNotifier.showSendBtn(true);
              Future.delayed(const Duration(milliseconds: 500), () async {
                await typingNotice(true);
              });
            } else {
              chatInputNotifier.showSendBtn(false);
              Future.delayed(const Duration(milliseconds: 500), () async {
                await typingNotice(false);
              });
            }
          },
          textInputAction: (Platform.isAndroid || Platform.isIOS)
              ? TextInputAction.send
              : TextInputAction.newline,
          enabled: chatInputState.allowEdit,
          onSubmitted: (value) => onSendButtonPressed(),
          style: Theme.of(context).textTheme.bodySmall,
          cursorColor: Theme.of(context).colorScheme.primary,
          maxLines: 6,
          minLines: 1,
          focusNode: ref.watch(chatInputFocusProvider),
          decoration: InputDecoration(
            isCollapsed: true,
            prefixIcon: isEncrypted
                ? Icon(
                    Icons.shield,
                    size: 18,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  )
                : null,
            suffixIcon: InkWell(
              onTap: () => chatInputState.emojiPickerVisible
                  ? chatInputNotifier.emojiPickerVisible(false)
                  : chatInputNotifier.emojiPickerVisible(true),
              child: const Icon(Icons.emoji_emotions),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 0.5,
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 0.5,
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 0.5,
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
            hintText: isEncrypted
                ? 'New Encrypted Message '
                : AppLocalizations.of(context)!.newMessage,
            hintStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
            contentPadding: const EdgeInsets.all(15),
            hintMaxLines: 1,
          ),
          mentions: [
            Mention(
              trigger: '@',
              style: TextStyle(
                height: 0.5,
                background: Paint()
                  ..color = Theme.of(context).colorScheme.neutral2
                  ..strokeWidth = 13
                  ..strokeJoin = StrokeJoin.round
                  ..style = PaintingStyle.stroke,
              ),
              data: chatInputState.mentions,
              suggestionBuilder: (Map<String, dynamic> roomMember) {
                final authorId = roomMember['link'];
                final title = roomMember['display'] ?? authorId;
                return ListTile(
                  leading: MentionProfileBuilder(
                    authorId: authorId,
                    title: title,
                  ),
                  title: Wrap(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 15),
                      Text(
                        authorId,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.neutral5,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // send typing event from client
  Future<bool> typingNotice(bool typing) async {
    return await convo.typingNotice(typing);
  }
}

class _ReplyContentWidget extends StatelessWidget {
  const _ReplyContentWidget({
    required this.convo,
    required this.msg,
    required this.messageWidget,
  });

  final Convo convo;
  final Message msg;
  final Widget messageWidget;

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          convo: convo,
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      final textMsg = msg as TextMessage;
      return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          defaultTextStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 3,
        ),
      );
    }
    return messageWidget;
  }
}

class _EditMessageContentWidget extends StatelessWidget {
  const _EditMessageContentWidget({
    required this.convo,
    required this.msg,
  });

  final Convo convo;
  final Message msg;

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          convo: convo,
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      final textMsg = msg as TextMessage;
      return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          defaultTextStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 3,
        ),
      );
    }
    return Container();
  }
}
