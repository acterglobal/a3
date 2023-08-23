import 'dart:io';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/mention_profile_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:mime/mime.dart';

class CustomChatInput extends ConsumerWidget {
  const CustomChatInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(clientProvider)!.userId().toString();
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final chatRoomNotifier = ref.watch(chatRoomProvider.notifier);
    final repliedToMessage =
        ref.watch(chatRoomProvider.notifier).repliedToMessage;
    final isAuthor = ref.watch(chatRoomProvider.notifier).isAuthor();
    final accountProfile = ref.watch(accountProfileProvider);
    final showReplyView = ref.watch(
      chatInputProvider.select((ci) => ci.showReplyView),
    );
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        Visibility(
          visible: showReplyView,
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
                  repliedToMessage != null
                      ? Consumer(builder: replyBuilder)
                      : const SizedBox.shrink(),
                  if (repliedToMessage != null &&
                      chatInputState.replyWidget != null)
                    _ReplyContentWidget(
                      msg: repliedToMessage,
                      messageWidget: chatInputState.replyWidget,
                    ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: !chatInputState.emojiRowVisible,
          replacement: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    if (isAuthor) {
                      popUpDialog(
                        context: context,
                        title: const Text(
                          'Are you sure you want to delete this message? This action cannot be undone.',
                        ),
                        btnText: 'No',
                        btn2Text: 'Yes',
                        btn2Color: Theme.of(context).colorScheme.onError,
                        onPressedBtn: () => context.pop(),
                        onPressedBtn2: () async {
                          final messageId = ref
                              .read(chatRoomProvider.notifier)
                              .currentMessageId;
                          if (messageId != null) {
                            try {
                              await chatRoomNotifier
                                  .redactRoomMessage(messageId);
                              chatInputNotifier.emojiRowVisible(false);
                              chatRoomNotifier.currentMessageId = null;
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (e) {
                              context.pop();
                              customMsgSnackbar(
                                context,
                                e.toString(),
                              );
                            }
                          } else {
                            debugPrint(messageId);
                          }
                        },
                      );
                    } else {
                      customMsgSnackbar(
                        context,
                        'Report message isn\'t implemented yet',
                      );
                    }
                  },
                  child: Text(
                    isAuthor ? 'Unsend' : 'Report',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    accountProfile.when(
                      data: (data) => ActerAvatar(
                        uniqueId: userId,
                        mode: DisplayMode.User,
                        displayName: data.profile.displayName ?? userId,
                        avatar: data.profile.getAvatarImage(),
                        size: data.profile.hasAvatar() ? 18 : 36,
                      ),
                      error: (e, st) {
                        debugPrint('Error loading due to $e');
                        return ActerAvatar(
                          uniqueId: userId,
                          mode: DisplayMode.User,
                          displayName: userId,
                          size: 36,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                    ),
                    const Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: _TextInputWidget(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => handleAttachment(ref, context),
                        child: const Icon(Atlas.paperclip_attachment),
                      ),
                    ),
                    if (chatInputState.sendBtnVisible)
                      InkWell(
                        onTap: () => onSendButtonPressed(ref),
                        child: const Icon(Atlas.paper_airplane),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        EmojiPickerWidget(
          size: size,
        ),
      ],
    );
  }

  void handleAttachment(WidgetRef ref, BuildContext ctx) async {
    var chatRoomNotifier = ref.read(chatRoomProvider.notifier);
    await chatRoomNotifier.handleFileSelection(ctx);
    if (ctx.mounted) {
      var selectionList = chatRoomNotifier.fileList;
      String fileName = selectionList.first.path.split('/').last;
      final mimeType = lookupMimeType(selectionList.first.path);
      popUpDialog(
        context: ctx,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Upload Files (${selectionList.length})',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        subtitle: Visibility(
          visible: selectionList.length <= 5,
          child: _FileWidget(mimeType, selectionList.first),
        ),
        description: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(fileName, style: Theme.of(ctx).textTheme.bodySmall),
        ),
        btnText: 'Cancel',
        btn2Text: 'Upload',
        btn2Color: Theme.of(ctx).colorScheme.success,
        btnBorderColor: Theme.of(ctx).colorScheme.errorContainer,
        onPressedBtn: () => ctx.pop(),
        onPressedBtn2: () async {
          ctx.pop();
          await chatRoomNotifier.handleFileUpload();
        },
      );
    }
  }

  Widget replyBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final roomNotifier = ref.watch(chatRoomProvider.notifier);
    final authorId = roomNotifier.repliedToMessage!.author.id;
    final replyProfile = ref.watch(memberProfileProvider(authorId));
    final inputNotifier = ref.watch(chatInputProvider.notifier);
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
            inputNotifier.setReplyWidget(null);
          },
          child: const Icon(
            Atlas.xmark_circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

Future<void> onSendButtonPressed(WidgetRef ref) async {
  final inputNotifier = ref.read(chatInputProvider.notifier);
  final roomNotifier = ref.read(chatRoomProvider.notifier);
  final mentionState = ref.read(mentionKeyProvider).currentState!;
  final markDownProvider = ref.read(messageMarkDownProvider);
  final markDownNotifier = ref.read(messageMarkDownProvider.notifier);

  inputNotifier.showSendBtn(false);
  String markdownText = mentionState.controller!.text;
  int messageLength = markdownText.length;
  markDownProvider.forEach((key, value) {
    markdownText = markdownText.replaceAll(key, value);
  });
  await roomNotifier.handleSendPressed(markdownText, messageLength);
  markDownNotifier.update((state) => {});
  mentionState.controller!.clear();
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

class _TextInputWidget extends ConsumerStatefulWidget {
  const _TextInputWidget();

  @override
  ConsumerState<_TextInputWidget> createState() =>
      _TextInputWidgetConsumerState();
}

class _TextInputWidgetConsumerState extends ConsumerState<_TextInputWidget> {
  @override
  Widget build(BuildContext context) {
    final mentionList = ref.watch(mentionListProvider);
    final mentionKey = ref.watch(mentionKeyProvider);
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final chatRoomNotifier = ref.watch(chatRoomProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final width = MediaQuery.of(context).size.width;
    return FlutterMentions(
      key: mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      suggestionListWidth: width >= 770 ? width * 0.6 : width * 0.8,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(roomMember, ref);
      },
      suggestionListDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.neutral2,
        borderRadius: BorderRadius.circular(6),
      ),
      onChanged: (String value) async {
        final focusNode = ref.read(chatInputFocusProvider);
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
        if (value.isNotEmpty) {
          chatInputNotifier.showSendBtn(true);
          await chatRoomNotifier.typingNotice(true);
        } else {
          chatInputNotifier.showSendBtn(false);
          await chatRoomNotifier.typingNotice(false);
        }
      },
      textInputAction: TextInputAction.send,
      onSubmitted: (value) => onSendButtonPressed(ref),
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      maxLines:
          MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 2,
      minLines: 1,
      focusNode: ref.watch(chatInputFocusProvider),
      decoration: InputDecoration(
        isCollapsed: true,
        fillColor: Theme.of(context).colorScheme.primaryContainer,
        suffixIcon: InkWell(
          onTap: () => chatInputState.emojiPickerVisible
              ? chatInputNotifier.emojiPickerVisible(false)
              : chatInputNotifier.emojiPickerVisible(true),
          child: const Icon(Icons.emoji_emotions),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        filled: true,
        hintText: AppLocalizations.of(context)!.newMessage,
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
          data: mentionList,
          matchAll: true,
          suggestionBuilder: (Map<String, dynamic> roomMember) {
            final authorId = roomMember['link'];
            final title = roomMember['display'] ?? authorId;
            return ListTile(
              leading: MentionProfileBuilder(
                authorId: authorId,
                title: title,
              ),
              title: Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
        )
      ],
    );
  }

  void _handleMentionAdd(Map<String, dynamic> roomMember, WidgetRef ref) {
    String authorId = roomMember['link'];
    String displayName = roomMember['display'] ?? authorId;
    ref.read(messageMarkDownProvider).addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$authorId)',
    });
  }
}

class _ReplyContentWidget extends StatelessWidget {
  const _ReplyContentWidget({
    required this.msg,
    required this.messageWidget,
  });

  final Message? msg;
  final Widget? messageWidget;

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
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
    return messageWidget ?? const SizedBox.shrink();
  }
}

class EmojiPickerWidget extends ConsumerStatefulWidget {
  final Size size;

  const EmojiPickerWidget({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  ConsumerState<EmojiPickerWidget> createState() =>
      _EmojiPickerWidgetConsumerState();
}

class _EmojiPickerWidgetConsumerState extends ConsumerState<EmojiPickerWidget> {
  @override
  Widget build(BuildContext context) {
    final chatInputState = ref.watch(chatInputProvider);
    return Offstage(
      offstage: !chatInputState.emojiPickerVisible,
      child: SizedBox(
        height: widget.size.height * 0.3,
        child: EmojiPicker(
          onEmojiSelected: handleEmojiSelected,
          onBackspacePressed: handleBackspacePressed,
          config: Config(
            columns: 8,
            bgColor: Theme.of(context).colorScheme.neutral,
            emojiSizeMax: 36,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            initCategory: Category.SMILEYS,
            recentTabBehavior: RecentTabBehavior.RECENT,
            recentsLimit: 28,
            noRecents: Text(
              AppLocalizations.of(context)!.noRecents,
            ),
            tabIndicatorAnimDuration: kTabScrollDuration,
            categoryIcons: const CategoryIcons(),
            buttonMode: ButtonMode.MATERIAL,
          ),
        ),
      ),
    );
  }

  void handleEmojiSelected(Category? category, Emoji emoji) {
    final mentionState = ref.read(mentionKeyProvider).currentState!;
    mentionState.controller!.text += emoji.emoji;
    ref.read(chatInputProvider.notifier).showSendBtn(true);
  }

  void handleBackspacePressed() {
    final mentionState = ref.read(mentionKeyProvider).currentState!;
    final newValue =
        mentionState.controller!.text.characters.skipLast(1).string;
    mentionState.controller!.text = newValue;
    if (newValue.isEmpty) {
      ref.read(chatInputProvider.notifier).showSendBtn(false);
    }
  }
}
