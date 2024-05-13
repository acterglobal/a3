import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/features/attachments/widgets/attachment_container.dart';
import 'package:acter/features/attachments/widgets/attachment_options.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
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
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::custom_input');

final _sendButtonVisible = StateProvider.family<bool, String>(
  (ref, roomId) => ref.watch(
    chatInputProvider(roomId).select((value) => value.message.isNotEmpty),
  ),
);

final _allowEdit = StateProvider.family<bool, String>(
  (ref, roomId) => ref.watch(
    chatInputProvider(roomId)
        .select((state) => state.sendingState == SendingState.preparing),
  ),
);

class CustomChatInput extends ConsumerWidget {
  final String roomId;
  final void Function(bool)? onTyping;
  const CustomChatInput({required this.roomId, this.onTyping, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(roomId));
    return membership.when(
      skipLoadingOnReload:
          true, // avoid widget refresh and thus text focus updates upon room changes
      data: (member) => buildData(context, ref, member),
      error: (error, stack) {
        _log.severe('Error loading membership', error, stack);
        return Expanded(
          child: Text(L10n.of(context).loadingChatsFailed(error)),
        );
      },
      loading: () {
        return const Skeletonizer(
          child: Row(
            children: [
              Icon(Atlas.paperclip_attachment_thin),
              Expanded(child: Text('loading')),
            ],
          ),
        );
      },
    );
  }

  Widget buildData(BuildContext context, WidgetRef ref, Member? membership) {
    final canSend = membership?.canString('CanSendChatMessages') == true;
    if (!canSend) {
      return FrostEffect(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
          ),
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
                  L10n.of(context).chatMissingPermissionsToSend,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return _ChatInput(roomId: roomId, onTyping: onTyping);
    }
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
  GlobalKey<FlutterMentionsState> mentionKey =
      GlobalKey<FlutterMentionsState>();

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
  }

  void handleBackspacePressed() {
    final newValue =
        mentionKey.currentState!.controller!.text.characters.skipLast(1).string;
    mentionKey.currentState!.controller!.text = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    final selectedMessage = ref.watch(
      chatInputProvider(roomId).select(
        (value) => value.selectedMessage,
      ),
    );

    if (selectedMessage == null) {
      return renderMain(context);
    }

    return switch (ref.watch(
      chatInputProvider(roomId).select(
        (value) => value.selectedMessageState,
      ),
    )) {
      SelectedMessageState.replyTo => renderReplyView(context, selectedMessage),
      SelectedMessageState.edit => renderEditView(context, selectedMessage),
      SelectedMessageState.none ||
      SelectedMessageState.actions =>
        renderMain(context)
    };
  }

  Widget renderMain(BuildContext context) {
    return renderChatInputArea(context, null);
  }

  Widget renderChatInputArea(BuildContext context, Widget? child) {
    final roomId = widget.roomId;
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull ?? false;

    return Column(
      children: [
        if (child != null) child,
        FrostEffect(
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
                      onTap: () => onSelectAttachment(context),
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
                        roomId: widget.roomId,
                        onSendButtonPressed: () =>
                            onSendButtonPressed(context, ref),
                        isEncrypted: isEncrypted,
                        onTyping: widget.onTyping,
                      ),
                    ),
                  ),
                  if (ref.watch(_sendButtonVisible(roomId)))
                    renderSendButton(context, roomId),
                ],
              ),
            ),
          ),
        ),
        if (ref.watch(
          chatInputProvider(roomId).select((value) => value.emojiPickerVisible),
        ))
          EmojiPickerWidget(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 3,
            ),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
          ),
      ],
    );
  }

  Widget renderSendButton(BuildContext context, String roomId) {
    final allowEditing = ref.watch(_allowEdit(roomId));

    if (allowEditing) {
      return IconButton.filled(
        iconSize: 20,
        onPressed: () => onSendButtonPressed(context, ref),
        icon: const Icon(
          Icons.send,
        ),
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
    final size = MediaQuery.of(context).size;
    final roomId = widget.roomId;

    return renderChatInputArea(
      context,
      FrostEffect(
        widgetWidth: size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
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
                Consumer(
                  builder: (ctx, ref, child) =>
                      replyBuilder(roomId, repliedToMessage),
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
    final size = MediaQuery.of(context).size;
    return renderChatInputArea(
      context,
      FrostEffect(
        widgetWidth: size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
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
                Consumer(builder: editMessageBuilder),
                _EditMessageContentWidget(
                  roomId: widget.roomId,
                  msg: editMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onSelectAttachment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      builder: (ctx) => AttachmentOptions(
        onTapCamera: () async {
          XFile? imageFile =
              await ImagePicker().pickImage(source: ImageSource.camera);
          if (imageFile != null) {
            List<File> files = [File(imageFile.path)];

            if (context.mounted) {
              attachmentConfirmation(
                files,
                AttachmentType.camera,
                handleFileUpload,
              );
            }
          }
        },
        onTapImage: () async {
          XFile? imageFile =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (imageFile != null) {
            List<File> files = [File(imageFile.path)];

            if (context.mounted) {
              attachmentConfirmation(
                files,
                AttachmentType.image,
                handleFileUpload,
              );
            }
          }
        },
        onTapVideo: () async {
          XFile? imageFile =
              await ImagePicker().pickVideo(source: ImageSource.gallery);
          if (imageFile != null) {
            List<File> files = [File(imageFile.path)];

            if (context.mounted) {
              attachmentConfirmation(
                files,
                AttachmentType.video,
                handleFileUpload,
              );
            }
          }
        },
        onTapFile: () async {
          final selectedFiles = await handleFileSelection(ctx);

          if (context.mounted) {
            attachmentConfirmation(
              selectedFiles,
              AttachmentType.file,
              handleFileUpload,
            );
          }
        },
      ),
    );
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

  void attachmentConfirmation(
    List<File>? selectedFiles,
    AttachmentType type,
    Future<void> Function(
      List<File> files,
      AttachmentType attachmentType,
    ) handleFileUpload,
  ) {
    final size = MediaQuery.of(context).size;
    if (selectedFiles != null && selectedFiles.isNotEmpty) {
      isLargeScreen(context)
          ? showAdaptiveDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width * 0.5,
                    maxHeight: size.height * 0.5,
                  ),
                  child: _FileWidget(selectedFiles, type, handleFileUpload),
                ),
              ),
            )
          : showModalBottomSheet(
              context: context,
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: _FileWidget(selectedFiles, type, handleFileUpload),
              ),
            );
    }
  }

  Future<void> handleFileUpload(
    List<File> files,
    AttachmentType attachmentType,
  ) async {
    final roomId = widget.roomId;
    final client = ref.read(alwaysClientProvider);
    final inputState = ref.read(chatInputProvider(roomId));
    final lang = L10n.of(context);
    final stream = await ref.read(
      timelineStreamProviderForId(widget.roomId).future,
    );

    try {
      for (File file in files) {
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
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              imageDraft,
            );
          } else {
            await stream.sendMessage(imageDraft);
          }
        } else if (mimeType.startsWith('audio/') &&
            attachmentType == AttachmentType.audio) {
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              audioDraft,
            );
          } else {
            await stream.sendMessage(audioDraft);
          }
        } else if (mimeType.startsWith('video/') &&
            attachmentType == AttachmentType.video) {
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(file.lengthSync());

          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              videoDraft,
            );
          } else {
            await stream.sendMessage(videoDraft);
          }
        } else {
          final fileDraft =
              client.fileDraft(file.path, mimeType).size(file.lengthSync());

          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              fileDraft,
            );
          } else {
            await stream.sendMessage(fileDraft);
          }
        }
      }
    } catch (e, s) {
      _log.severe('error occurred', e, s);
    }

    ref.read(chatInputProvider(roomId).notifier).unsetSelectedMessage();
  }

  Widget replyBuilder(String roomId, Message repliedToMessage) {
    final authorId = repliedToMessage.author.id;
    final replyProfile =
        ref.watch(roomMemberProvider((userId: authorId, roomId: roomId)));
    final inputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(
          Icons.reply_rounded,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        replyProfile.when(
          data: (data) => ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: authorId,
              displayName: data.profile.displayName ?? authorId,
              avatar: data.profile.getAvatarImage(),
            ),
            size: 12,
          ),
          error: (e, st) {
            _log.severe('Error loading avatar', e, st);
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
          L10n.of(context).replyTo('${toBeginningOfSentenceCase(authorId)}'),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            inputNotifier.unsetSelectedMessage();
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
    final roomId = widget.roomId;
    final inputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(
          Atlas.pencil_edit_thin,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          L10n.of(context).editMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            final mentionState = mentionKey.currentState;
            if (mentionKey.currentState != null) {
              mentionState!.controller!.clear();
            }
            inputNotifier.unsetSelectedMessage();
            FocusScope.of(context).unfocus();
          },
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed(BuildContext context, WidgetRef ref) async {
    if (mentionKey.currentState!.controller!.text.isEmpty) return;
    final lang = L10n.of(context);
    final roomId = widget.roomId;
    ref.read(chatInputProvider(roomId).notifier).startSending();
    try {
      // end the typing notification
      if (widget.onTyping != null) {
        widget.onTyping!(false);
      }

      final mentions = ref.read(chatInputProvider(roomId)).mentions;
      final mentionState = mentionKey.currentState!;
      String markdownText = mentionState.controller!.text;
      final userMentions = [];
      mentions.forEach((key, value) {
        userMentions.add(value);
        markdownText = markdownText.replaceAll(
          '@$key',
          '[@$key](https://matrix.to/#/$value)',
        );
      });

      // make the actual draft
      final client = ref.read(alwaysClientProvider);
      final draft = client.textMarkdownDraft(markdownText);

      for (final userId in userMentions) {
        draft.addMention(userId);
      }

      // actually send it out
      final inputState = ref.read(chatInputProvider(roomId));
      final stream = await ref.read(
        timelineStreamProviderForId(widget.roomId).future,
      );

      if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
        await stream.replyMessage(inputState.selectedMessage!.id, draft);
      } else if (inputState.selectedMessageState == SelectedMessageState.edit) {
        await stream.editMessage(inputState.selectedMessage!.id, draft);
      } else {
        await stream.sendMessage(draft);
      }
      ref.read(chatInputProvider(roomId).notifier).messageSent();
      mentionState.controller!.clear();
    } catch (error, stackTrace) {
      _log.severe('Sending chat message failed', error, stackTrace);
      EasyLoading.showError(
        lang.failedToSend(error),
        duration: const Duration(seconds: 3),
      );
      ref.read(chatInputProvider(roomId).notifier).sendingFailed();
    }
  }
}

class _FileWidget extends ConsumerWidget {
  final List<File> selectedFiles;
  final AttachmentType type;
  final Future<void> Function(
    List<File> files,
    AttachmentType attachmentType,
  ) handleFileUpload;

  const _FileWidget(this.selectedFiles, this.type, this.handleFileUpload);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${L10n.of(context).attachments} (${selectedFiles.length})'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5.0,
            runSpacing: 10.0,
            children: <Widget>[
              for (var file in selectedFiles) _filePreview(context, file),
            ],
          ),
          _buildActionBtns(context),
        ],
      ),
    );
  }

  Widget _buildActionBtns(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(L10n.of(context).cancel),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              Navigator.of(context).pop();
              handleFileUpload(selectedFiles, type);
            },
            child: Text(L10n.of(context).send),
          ),
        ],
      ),
    );
  }

  Widget _filePreview(BuildContext context, File file) {
    final fileName = file.path.split('/').last;
    if (type == AttachmentType.camera || type == AttachmentType.image) {
      return AttachmentContainer(
        name: fileName,
        child: Image.file(file, height: 200, fit: BoxFit.cover),
      );
    } else if (type == AttachmentType.audio) {
      return AttachmentContainer(
        name: fileName,
        child: const Center(
          child: Icon(Atlas.file_sound_thin),
        ),
      );
    } else if (type == AttachmentType.video) {
      return AttachmentContainer(
        name: fileName,
        child: const Center(
          child: Icon(Atlas.file_video_thin),
        ),
      );
    }
    //FIXME: cover all mime extension cases?
    else {
      return AttachmentContainer(
        name: fileName,
        child: const Center(
          child: Icon(Atlas.plus_file_thin),
        ),
      );
    }
  }
}

class _TextInputWidget extends ConsumerWidget {
  final GlobalKey<FlutterMentionsState> mentionKey;
  final String roomId;
  final Function() onSendButtonPressed;
  final bool isEncrypted;
  final FocusNode chatFocus = FocusNode();
  final void Function(bool)? onTyping;

  _TextInputWidget({
    required this.mentionKey,
    required this.roomId,
    required this.onSendButtonPressed,
    this.onTyping,
    this.isEncrypted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatMentions = ref.watch(chatMentionsProvider(roomId));
    final width = MediaQuery.of(context).size.width;
    ref.listen(chatInputProvider(roomId), (prev, next) {
      if (next.selectedMessageState == SelectedMessageState.edit &&
          (prev?.selectedMessageState != next.selectedMessageState ||
              next.selectedMessage != prev?.selectedMessage)) {
        // a new message has been selected to be edited or switched from reply
        // to edit, force refresh the inner text controller to reflect that
        mentionKey.currentState!.controller!.text = next.message;
        chatFocus.requestFocus();
      } else if (next.selectedMessageState == SelectedMessageState.replyTo &&
          (next.selectedMessage != prev?.selectedMessage ||
              prev?.selectedMessageState != next.selectedMessageState)) {
        chatFocus.requestFocus();
      }
    });
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          onSendButtonPressed();
        },
      },
      child: Focus(
        child: FlutterMentions(
          key: mentionKey,
          // restore input if available, but only as a read on startup
          defaultText: ref
              .read(chatInputProvider(roomId).select((value) => value.message)),
          suggestionPosition: SuggestionPosition.Top,
          suggestionListWidth: width >= 770 ? width * 0.6 : width * 0.8,
          onMentionAdd: (roomMember) => onMentionAdd(roomMember, ref),
          suggestionListDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(6),
          ),
          onChanged: (String value) async {
            ref.read(chatInputProvider(roomId).notifier).updateMessage(value);
            if (onTyping != null) {
              onTyping!(value.isNotEmpty);
            }
          },
          textInputAction: TextInputAction.newline,
          enabled: ref.watch(_allowEdit(roomId)),
          onSubmitted: (value) => onSendButtonPressed(),
          style: Theme.of(context).textTheme.bodyMedium,
          cursorColor: Theme.of(context).colorScheme.primary,
          maxLines: 6,
          minLines: 1,
          focusNode: chatFocus,
          onTap: () => onTextTap(
            ref.read(chatInputProvider(roomId)).emojiPickerVisible,
            ref,
          ),
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
              onTap: () => onSuffixTap(
                ref.read(chatInputProvider(roomId)).emojiPickerVisible,
                context,
                ref,
              ),
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
                ? L10n.of(context).newEncryptedMessage
                : L10n.of(context).newMessage,
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
              data: chatMentions.valueOrNull ?? [],
              suggestionBuilder: (Map<String, dynamic> mentionRecord) {
                final authorId = mentionRecord['id'];
                final title = mentionRecord['displayName'];
                return ListTile(
                  leading: MentionProfileBuilder(
                    roomId: roomId,
                    authorId: authorId,
                  ),
                  title: title != null
                      ? Wrap(
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              authorId,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.neutral5,
                                  ),
                            ),
                          ],
                        )
                      : Text(
                          authorId,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.neutral5,
                              ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void onMentionAdd(Map<String, dynamic> roomMember, WidgetRef ref) {
    String authorId = roomMember['id'];
    String displayName = roomMember['display'];
    ref
        .read(chatInputProvider(roomId).notifier)
        .addMention(displayName, authorId);
  }

  void onTextTap(bool emojiPickerVisible, WidgetRef ref) {
    final chatInputNotifier = ref.read(chatInputProvider(roomId).notifier);

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
    final chatInputNotifier = ref.read(chatInputProvider(roomId).notifier);
    if (!emojiPickerVisible) {
      //Hide soft keyboard and then show Emoji Picker
      FocusScope.of(context).unfocus();
      chatInputNotifier.emojiPickerVisible(true);
    } else {
      //Hide Emoji Picker
      chatInputNotifier.emojiPickerVisible(false);
    }
  }
}

class _ReplyContentWidget extends StatelessWidget {
  final String roomId;
  final Message msg;

  const _ReplyContentWidget({
    required this.roomId,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
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
    } else if (msg is FileMessage) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          msg.metadata?['content'],
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
  }
}

class _EditMessageContentWidget extends StatelessWidget {
  final String roomId;
  final Message msg;

  const _EditMessageContentWidget({
    required this.roomId,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
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
