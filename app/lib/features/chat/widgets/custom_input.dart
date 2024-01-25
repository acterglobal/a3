import 'dart:io';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/chat/chat_utils/chat_utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/chat_attachment_options.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/mention_profile_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:mime/mime.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum ChatAttachmentType { camera, image, audio, video, file }

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
    final userId = ref.watch(alwaysClientProvider).userId().toString();
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
    final showEditButton = ref.watch(
      chatInputProvider(roomId).select((ci) => ci.editBtnVisible),
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
      // Get cursor current position
      var cursorPos = mentionState.controller!.selection.base.offset;

      // Right text of cursor position
      String suffixText = mentionState.controller!.text.substring(cursorPos);

      // Get the left text of cursor
      String prefixText = mentionState.controller!.text.substring(0, cursorPos);

      int emojiLength = emoji.emoji.length;

      // Add emoji at current current cursor position
      mentionState.controller!.text = prefixText + emoji.emoji + suffixText;

      // Cursor move to end of added emoji character
      mentionState.controller!.selection = TextSelection(
        baseOffset: cursorPos + emojiLength,
        extentOffset: cursorPos + emojiLength,
      );
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
                    .primaryContainer,
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
                        ? Consumer(
                            builder: (ctx, ref, child) => replyBuilder(roomId),
                          )
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
                    .primaryContainer,
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
                              OutlinedButton(
                                onPressed: () => Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(),
                                child: const Text('No'),
                              ),
                              ElevatedButton(
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
                                child: const Text('Yes'),
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
                  if (showEditButton)
                    InkWell(
                      onTap: () => onPressEditMessage(roomId, currentMessageId),
                      child: const Text('Edit'),
                    ),
                  InkWell(
                    onTap: () => customMsgSnackbar(
                      context,
                      'More options not implemented yet',
                    ),
                    child: const Text('More'),
                  ),
                ],
              ),
            ),
          ),
          child: FrostEffect(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
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
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isDismissible: true,
                          enableDrag: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              topLeft: Radius.circular(20),
                            ),
                          ),
                          builder: (ctx) => ChatAttachmentOptions(
                            onTapCamera: () async {
                              XFile? imageFile = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (imageFile != null) {
                                List<File> files = [File(imageFile.path)];
                                handleAttachment(
                                  ref,
                                  files,
                                  ChatAttachmentType.camera,
                                );
                              }
                            },
                            onTapImage: () async {
                              XFile? imageFile = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              if (imageFile != null) {
                                List<File> files = [File(imageFile.path)];
                                handleAttachment(
                                  ref,
                                  files,
                                  ChatAttachmentType.image,
                                );
                              }
                            },
                            onTapVideo: () async {
                              XFile? imageFile = await ImagePicker()
                                  .pickVideo(source: ImageSource.gallery);
                              if (imageFile != null) {
                                List<File> files = [File(imageFile.path)];
                                handleAttachment(
                                  ref,
                                  files,
                                  ChatAttachmentType.video,
                                );
                              }
                            },
                            onTapFile: () async {
                              var selectedFiles = await handleFileSelection(
                                ctx,
                              );
                              handleAttachment(
                                ref,
                                selectedFiles,
                                ChatAttachmentType.file,
                              );
                            },
                          ),
                        ),
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
              MediaQuery.of(context).size.height / 3,
            ),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
          ),
        ),
      ],
    );
  }

  void onPressEditMessage(String roomId, String? currentMessageId) {
    final emojiRowVisible = ref.read(
      chatInputProvider(roomId).select((ci) {
        return ci.emojiRowVisible;
      }),
    );
    final inputNotifier = ref.read(chatInputProvider(roomId).notifier);
    if (emojiRowVisible) {
      inputNotifier.setCurrentMessageId(null);
      inputNotifier.emojiRowVisible(false);
    }

    inputNotifier.showEditView(true);
    final message =
        ref.read(chatStateProvider(widget.convo)).messages.firstWhere(
              (element) => element.id == currentMessageId,
            );
    inputNotifier.setEditMessage(message);
    if (message is TextMessage) {
      // Parse String Data to HTML document
      final document = parse(message.text);

      if (document.body != null) {
        // Get message data
        String msg = message.text.trim();

        // Get list of 'A Tags' values
        final aTagElementList = document.getElementsByTagName('a');

        for (final aTagElement in aTagElementList) {
          final userMentionMessageData =
              parseUserMentionMessage(msg, aTagElement);
          msg = userMentionMessageData.parsedMessage;

          // Adding mentions data
          ref.read(chatInputProvider(roomId).notifier).addMention(
                userMentionMessageData.displayName,
                userMentionMessageData.userName,
              );
        }

        // Parse data
        final messageDocument = parse(msg);
        final messageBodyText = messageDocument.body?.text ?? '';

        // Update text value with msg value
        ref
            .read(_textValuesProvider(roomId).notifier)
            .update((state) => messageBodyText);
      }
    }

    final chatInputFocusState = ref.read(chatInputFocusProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      FocusScope.of(context).requestFocus(chatInputFocusState.state);
    });
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

  void handleAttachment(
    WidgetRef ref,
    List<File>? selectedFiles,
    ChatAttachmentType chatAttachmentType,
  ) async {
    if (context.mounted) {
      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        String fileName = selectedFiles.first.path.split('/').last;
        final mimeType = lookupMimeType(selectedFiles.first.path);
        showAdaptiveDialog(
          context: context,
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
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await handleFileUpload(selectedFiles, chatAttachmentType);
                },
                child: const Text('Upload'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> handleFileUpload(
    List<File> files,
    ChatAttachmentType chatAttachmentType,
  ) async {
    final roomId = widget.convo.getRoomIdStr();
    final client = ref.read(clientProvider)!;
    final inputState = ref.read(chatInputProvider(roomId));
    final stream = widget.convo.timelineStream();

    try {
      for (File file in files) {
        String? mimeType = lookupMimeType(file.path);

        if (mimeType!.startsWith('image/') &&
            chatAttachmentType == ChatAttachmentType.image) {
          final bytes = file.readAsBytesSync();
          final image = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(file.lengthSync())
              .width(image.width)
              .height(image.height);
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(
              inputState.repliedToMessage!.id,
              imageDraft,
            );
          } else {
            await stream.sendMessage(imageDraft);
          }
        } else if (mimeType.startsWith('audio/') &&
            chatAttachmentType == ChatAttachmentType.audio) {
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(
              inputState.repliedToMessage!.id,
              audioDraft,
            );
          } else {
            await stream.sendMessage(audioDraft);
          }
        } else if (mimeType.startsWith('video/') &&
            chatAttachmentType == ChatAttachmentType.video) {
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(
              inputState.repliedToMessage!.id,
              videoDraft,
            );
          } else {
            await stream.sendMessage(videoDraft);
          }
        } else {
          final draft =
              client.fileDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(inputState.repliedToMessage!.id, draft);
          } else {
            await stream.sendMessage(draft);
          }
        }
      }
    } catch (e) {
      debugPrint('error occurred: $e');
    }

    if (inputState.repliedToMessage != null) {
      final notifier = ref.read(chatInputProvider(roomId).notifier);
      notifier.setRepliedToMessage(null);
      notifier.setEditMessage(null);
      notifier.showReplyView(false);
      notifier.showEditView(false);
      notifier.setReplyWidget(null);
      notifier.setEditWidget(null);
    }
  }

  Widget replyBuilder(String roomId) {
    final roomId = widget.convo.getRoomIdStr();
    final chatInputState = ref.watch(chatInputProvider(roomId));
    final authorId = chatInputState.repliedToMessage!.author.id;
    final replyProfile = ref
        .watch(memberProfileByInfoProvider((userId: authorId, roomId: roomId)));
    final inputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    return Row(
      children: [
        replyProfile.when(
          data: (profile) => ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: authorId,
              displayName: profile.displayName ?? authorId,
              avatar: profile.getAvatarImage(),
            ),
            size: 12,
          ),
          error: (e, st) {
            debugPrint('Error loading avatar due to $e');
            return ActerAvatar(
              mode: DisplayMode.DM,
              avatarInfo: AvatarInfo(
                uniqueId: authorId,
                displayName: authorId,
              ),
              size: 24,
            );
          },
          loading: () => Skeletonizer(
            child: ActerAvatar(
              mode: DisplayMode.DM,
              avatarInfo: AvatarInfo(uniqueId: authorId),
              size: 24,
            ),
          ),
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
            inputNotifier.showReplyView(false);
            inputNotifier.showEditView(false);
            inputNotifier.setReplyWidget(null);
            inputNotifier.setEditWidget(null);
            inputNotifier.setRepliedToMessage(null);
            inputNotifier.setEditMessage(null);
            FocusScope.of(context).unfocus();
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
    final roomId = widget.convo.getRoomIdStr();
    final inputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    return Row(
      children: [
        const SizedBox(width: 5),
        const Text(
          'Edit Message:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            final mentionState = mentionKey.currentState;
            if (mentionKey.currentState != null) {
              mentionState!.controller!.clear();
            }
            inputNotifier.showReplyView(false);
            inputNotifier.showEditView(false);
            inputNotifier.setReplyWidget(null);
            inputNotifier.setEditWidget(null);
            inputNotifier.setRepliedToMessage(null);
            inputNotifier.setEditMessage(null);
            FocusScope.of(context).unfocus();
          },
          child: const Icon(Atlas.xmark_circle),
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
    mentionReplacements.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });

    try {
      await handleSendPressed(markdownText);
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
  Future<void> handleSendPressed(String markdownMessage) async {
    final roomId = widget.convo.getRoomIdStr();
    final client = ref.read(clientProvider)!;
    final inputState = ref.read(chatInputProvider(roomId));
    // image or video is sent automatically
    // user will click "send" button explicitly for text only
    await widget.convo.typingNotice(false);
    final stream = widget.convo.timelineStream();
    final draft = client.textMarkdownDraft(markdownMessage);
    if (inputState.repliedToMessage != null) {
      await stream.replyMessage(inputState.repliedToMessage!.id, draft);
    } else if (inputState.editMessage != null) {
      await stream.editMessage(inputState.editMessage!.id, draft);
    } else {
      await stream.sendMessage(draft);
    }
    if (inputState.repliedToMessage != null || inputState.editMessage != null) {
      final notifier = ref.read(chatInputProvider(roomId).notifier);
      notifier.setRepliedToMessage(null);
      notifier.setEditMessage(null);
      notifier.showReplyView(false);
      notifier.showEditView(false);
      notifier.setReplyWidget(null);
      notifier.setEditWidget(null);
    }
  }
}

class _FileWidget extends ConsumerWidget {
  final String? mimeType;
  final File file;

  const _FileWidget(this.mimeType, this.file);

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
            color: Theme.of(context).colorScheme.background,
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
          textInputAction: TextInputAction.newline,
          enabled: chatInputState.allowEdit,
          onSubmitted: (value) => onSendButtonPressed(),
          style: Theme.of(context).textTheme.titleSmall,
          cursorColor: Theme.of(context).colorScheme.primary,
          maxLines: 6,
          minLines: 1,
          focusNode: ref.watch(chatInputFocusProvider),
          onTap: () {
            ///Hide emoji picker before input field get focus if
            ///Platform is mobile & Emoji picker is visible
            if (!isDesktop && chatInputState.emojiPickerVisible) {
              chatInputNotifier.emojiPickerVisible(false);
            }
          },
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
              onTap: () {
                if (!chatInputState.emojiPickerVisible) {
                  //Hide soft keyboard and then show Emoji Picker
                  FocusScope.of(context).unfocus();
                  chatInputNotifier.emojiPickerVisible(true);
                } else {
                  //Hide Emoji Picker
                  chatInputNotifier.emojiPickerVisible(false);
                }
              },
              child: const Icon(Icons.emoji_emotions),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 0.5,
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 0.5,
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 0.5,
                style: BorderStyle.solid,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            hintText: isEncrypted
                ? 'New Encrypted Message '
                : AppLocalizations.of(context)!.newMessage,
            hintStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
                    roomId: roomId,
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
  final Convo convo;
  final Message msg;
  final Widget messageWidget;

  const _ReplyContentWidget({
    required this.convo,
    required this.msg,
    required this.messageWidget,
  });

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
  final Convo convo;
  final Message msg;

  const _EditMessageContentWidget({
    required this.convo,
    required this.msg,
  });

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
