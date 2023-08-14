import 'dart:convert';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

class CustomChatInput extends ConsumerWidget {
  static const List<Icon> _attachmentIcons = [
    Icon(Atlas.camera_photo),
    Icon(Atlas.folder),
    Icon(Atlas.location),
  ];

  const CustomChatInput({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final chatRoomNotifier = ref.watch(chatRoomProvider.notifier);
    final repliedToMessage =
        ref.watch(chatRoomProvider.notifier).repliedToMessage;
    final isAuthor = ref.watch(chatRoomProvider.notifier).isAuthor();
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        Visibility(
          visible:
              ref.watch(chatInputProvider.select((ci) => ci.showReplyView)),
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
                      ? Row(
                          children: [
                            ActerAvatar(
                              uniqueId: repliedToMessage.author.id,
                              mode: DisplayMode.User,
                              displayName: repliedToMessage.author.firstName,
                              avatar: ref
                                  .watch(chatRoomProvider.notifier)
                                  .getUserProfile(
                                    repliedToMessage.author.id,
                                  )
                                  ?.getAvatarImage(),
                              size: ref
                                          .watch(chatRoomProvider.notifier)
                                          .getUserProfile(
                                            repliedToMessage.author.id,
                                          )!
                                          .getAvatarImage() ==
                                      null
                                  ? 24
                                  : 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Reply to ${toBeginningOfSentenceCase(repliedToMessage.author.id)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                chatInputNotifier.toggleReplyView(false);
                                chatInputNotifier.setReplyWidget(null);
                              },
                              child: const Icon(
                                Atlas.xmark_circle,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                  if (repliedToMessage != null &&
                      chatInputState.replyWidget != null)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: _ReplyContentWidget(
                          msg: repliedToMessage,
                          messageWidget: chatInputState.replyWidget,
                        ),
                      ),
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const _BuildAttachmentBtn(),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: _TextInputWidget(),
                      ),
                    ),
                    if (chatInputState.sendBtnVisible)
                      _BuildSendBtn(
                        onButtonPressed: () => onSendButtonPressed(ref),
                      ),
                    if (!chatInputState.sendBtnVisible) _BuildImageBtn(),
                    if (!chatInputState.sendBtnVisible)
                      const SizedBox(width: 10),
                    if (!chatInputState.sendBtnVisible) const _BuildAudioBtn(),
                  ],
                ),
              ),
            ),
          ),
        ),
        EmojiPickerWidget(
          size: size,
        ),
        AttachmentWidget(
          icons: CustomChatInput._attachmentIcons,
          size: size,
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed(WidgetRef ref) async {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    chatInputNotifier.showSendBtn(false);
    String markdownText =
        ref.read(mentionKeyProvider).currentState!.controller!.text;
    int messageLength = markdownText.length;
    ref.read(messageMarkDownProvider).forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    await ref.read(chatRoomProvider.notifier).handleSendPressed(
          markdownText,
          messageLength,
        );
    ref.read(messageMarkDownProvider.notifier).update((state) => {});
    ref.read(mentionKeyProvider).currentState!.controller!.clear();
  }
}

class _BuildAttachmentBtn extends ConsumerWidget {
  const _BuildAttachmentBtn();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final chatInputFocus = ref.watch(chatInputFocusProvider);
    return InkWell(
      onTap: () {
        chatInputState.attachmentVisible
            ? inputNotifier.toggleAttachment(false)
            : inputNotifier.toggleAttachment(true);
        chatInputFocus.unfocus();
        chatInputFocus.canRequestFocus = true;
      },
      child: const _BuildPlusBtn(),
    );
  }
}

class _BuildPlusBtn extends ConsumerWidget {
  const _BuildPlusBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatInputState = ref.watch(chatInputProvider);
    return Visibility(
      visible: chatInputState.attachmentVisible,
      replacement: const Icon(Atlas.plus_circle),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Icon(Atlas.xmark_circle),
      ),
    );
  }
}

class _TextInputWidget extends ConsumerStatefulWidget {
  const _TextInputWidget();

  @override
  ConsumerState<_TextInputWidget> createState() =>
      _TextInputWidgetConsumerState();
}

class _TextInputWidgetConsumerState extends ConsumerState<_TextInputWidget> {
  Future<void> onSendButtonPressed(WidgetRef ref) async {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    chatInputNotifier.showSendBtn(false);
    String markdownText =
        ref.read(mentionKeyProvider).currentState!.controller!.text;
    int messageLength = markdownText.length;
    ref.read(messageMarkDownProvider).forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    await ref.read(chatRoomProvider.notifier).handleSendPressed(
          markdownText,
          messageLength,
        );
    ref.read(messageMarkDownProvider.notifier).update((state) => {});
    ref.read(mentionKeyProvider).currentState!.controller!.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mentionList = ref.watch(mentionListProvider);
    final mentionKey = ref.watch(mentionKeyProvider);
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final chatRoomNotifier = ref.watch(chatRoomProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    return FlutterMentions(
      key: mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(roomMember, ref);
      },
      suggestionListDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.neutral2,
        borderRadius: BorderRadius.circular(6),
      ),
      onChanged: (String value) async {
        if (!ref.read(chatInputFocusProvider).hasFocus) {
          ref.read(chatInputFocusProvider).requestFocus();
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
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
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
            String title = roomMember['display'] ?? roomMember['link'];
            return ListTile(
              leading: SizedBox(
                width: 35,
                height: 35,
                child: ActerAvatar(
                  mode: DisplayMode.User,
                  uniqueId: roomMember['link'],
                  size: 20,
                  avatar: roomMember['avatar'],
                  displayName: roomMember['display'],
                ),
              ),
              title: Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    roomMember['link'],
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
    String userId = roomMember['link'];
    String displayName = roomMember['display'] ?? userId;
    ref.read(messageMarkDownProvider).addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$userId)',
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
    if (msg is TextMessage) {
      return messageWidget!;
    } else if (msg is ImageMessage) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100, maxWidth: 125),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.33),
            child: Image.memory(
              base64Decode(msg?.metadata?['base64']),
              fit: BoxFit.fill,
              cacheWidth: 125,
            ),
          ),
        ),
      );
    } else if (msg is FileMessage) {
      return messageWidget!;
    } else if (msg is CustomMessage) {
      return messageWidget!;
    } else {
      return const SizedBox.shrink();
    }
  }
}

class AttachmentWidget extends ConsumerWidget {
  final List<Icon> icons;
  final Size size;

  const AttachmentWidget({
    Key? key,
    required this.icons,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatInputState = ref.watch(chatInputProvider);
    return Offstage(
      offstage: !chatInputState.attachmentVisible,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: double.infinity,
        height: size.height * 0.3,
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: size.height * 0.172,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
              ),
              child: const _BuildSettingBtn(),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    InkWell(
                      onTap: () => onClickCamera(context, ref),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Atlas.camera),
                          SizedBox(height: 6),
                          Text(
                            'Camera',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => onClickFile(context, ref),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Atlas.folder),
                          SizedBox(height: 6),
                          Text(
                            'File',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => onClickLocation(context, ref),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Atlas.location),
                          SizedBox(height: 6),
                          Text(
                            'Location',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onClickCamera(BuildContext context, WidgetRef ref) =>
      ref.read(chatRoomProvider.notifier).handleMultipleImageSelection(context);

  void onClickFile(BuildContext context, WidgetRef ref) =>
      ref.read(chatRoomProvider.notifier).handleFileSelection(context);

  void onClickLocation(BuildContext context, WidgetRef ref) {}
}

class _BuildAudioBtn extends StatelessWidget {
  const _BuildAudioBtn();

  @override
  Widget build(BuildContext context) {
    return const Icon(Atlas.microphone);
  }
}

class _BuildImageBtn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => onClick(context, ref),
      child: const Icon(Atlas.camera_photo),
    );
  }

  void onClick(BuildContext context, WidgetRef ref) =>
      ref.read(chatRoomProvider.notifier).handleMultipleImageSelection(context);
}

class _BuildSettingBtn extends StatelessWidget {
  const _BuildSettingBtn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(AppLocalizations.of(context)!.grantAccessText),
        ),
        ElevatedButton(
          onPressed: () {},
          child: Text(
            AppLocalizations.of(context)!.settings,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _BuildSendBtn extends StatelessWidget {
  final Function()? onButtonPressed;

  const _BuildSendBtn({
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onButtonPressed,
      child: const Icon(Atlas.paper_airplane),
    );
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
    var mentionKey = ref.watch(mentionKeyProvider);
    mentionKey.currentState!.controller!.text += emoji.emoji;
    ref.read(chatInputProvider.notifier).showSendBtn(true);
  }

  void handleBackspacePressed() {
    var mentionKey = ref.watch(mentionKeyProvider);
    mentionKey.currentState!.controller!.text =
        mentionKey.currentState!.controller!.text.characters.skipLast(1).string;
    if (mentionKey.currentState!.controller!.text.isEmpty) {
      ref.read(chatInputProvider.notifier).showSendBtn(false);
    }
  }
}
