import 'dart:convert';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final client = ref.watch(clientProvider)!;
    final chatInputState = ref.watch(chatInputProvider);
    Size size = MediaQuery.of(context).size;
    return Container(
      color: Theme.of(context).colorScheme.onPrimary,
      child: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: ref
                    .watch(chatInputProvider.select((ci) => ci.showReplyView)),
                child: Container(
                  color: Theme.of(context).colorScheme.neutral,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.userId().toString() ==
                                        ref
                                            .watch(chatRoomProvider.notifier)
                                            .repliedToMessage
                                            ?.id
                                    ? 'Replying to you'
                                    : 'Replying to ${toBeginningOfSentenceCase(ref.watch(chatRoomProvider.notifier).repliedToMessage?.author.firstName)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (ref
                                          .watch(chatRoomProvider.notifier)
                                          .repliedToMessage !=
                                      null &&
                                  chatInputState.replyWidget != null)
                                _ReplyContentWidget(
                                  msg: ref
                                      .watch(chatRoomProvider.notifier)
                                      .repliedToMessage,
                                  messageWidget: chatInputState.replyWidget,
                                ),
                            ],
                          ),
                        ),
                        Flexible(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(chatInputProvider.notifier)
                                  .toggleReplyView();
                              ref
                                  .read(chatInputProvider.notifier)
                                  .setReplyWidget(null);
                            },
                            child: const Icon(
                              Atlas.xmark_circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
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
                        if (!chatInputState.sendBtnVisible)
                          const _BuildAudioBtn(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          EmojiPickerWidget(
            size: size,
          ),
          AttachmentWidget(
            icons: _attachmentIcons,
            size: size,
          ),
        ],
      ),
    );
  }

  Future<void> onSendButtonPressed(WidgetRef ref) async {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    chatInputNotifier.showSendBtn(false);
    String markdownText =
        chatInputNotifier.mentionKey.currentState!.controller!.text;
    String htmlText =
        chatInputNotifier.mentionKey.currentState!.controller!.text;
    int messageLength = markdownText.length;
    chatInputNotifier.messageTextMapMarkDown.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    chatInputNotifier.messageTextMapHtml.forEach((key, value) {
      htmlText = htmlText.replaceAll(key, value);
    });
    await ref.read(chatRoomProvider.notifier).handleSendPressed(
          markdownText,
          htmlText,
          messageLength,
        );
    chatInputNotifier.messageTextMapMarkDown.clear();
    chatInputNotifier.mentionKey.currentState!.controller!.clear();
  }
}

class _BuildAttachmentBtn extends ConsumerWidget {
  const _BuildAttachmentBtn();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    return InkWell(
      onTap: () {
        inputNotifier.toggleAttachment();
        inputNotifier.focusNode.unfocus();
        inputNotifier.focusNode.canRequestFocus = true;
      },
      child: const _BuildPlusBtn(),
    );
  }
}

class _BuildPlusBtn extends ConsumerWidget {
  const _BuildPlusBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Visibility(
      visible:
          ref.watch(chatInputProvider.select((ci) => ci.attachmentVisible)),
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

class _TextInputWidget extends ConsumerWidget {
  const _TextInputWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    final roomNotifier = ref.watch(chatRoomProvider.notifier);
    return FlutterMentions(
      key: ref.watch(chatInputProvider.notifier).mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(roomMember, ref);
      },
      onChanged: (String value) {
        debugPrint(value);
        if (value.isNotEmpty) {
          inputNotifier.showSendBtn(true);
          roomNotifier.typingNotice(true);
        } else {
          inputNotifier.showSendBtn(false);
          roomNotifier.typingNotice(false);
        }
      },
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      maxLines:
          MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 2,
      minLines: 1,
      focusNode: inputNotifier.focusNode,
      decoration: InputDecoration(
        isCollapsed: true,
        fillColor: Theme.of(context).colorScheme.primaryContainer,
        suffixIcon: InkWell(
          onTap: () {
            ref.read(chatInputProvider.notifier).emojiPickerVisible();
            inputNotifier.focusNode.unfocus();
            inputNotifier.focusNode.canRequestFocus = true;
          },
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
          data: ref.watch(mentionListProvider),
          matchAll: false,
          suggestionBuilder: (Map<String, dynamic> roomMember) {
            String title = roomMember.containsKey('display')
                ? roomMember['display']
                : simplifyUserId(roomMember['link']);
            return Container(
              color: Theme.of(context).colorScheme.neutral2,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.only(left: 50),
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
                title: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        )
      ],
    );
  }

  void _handleMentionAdd(Map<String, dynamic> roomMember, WidgetRef ref) {
    String userId = roomMember['link'];
    String displayName = roomMember.containsKey('display')
        ? roomMember['display']
        : simplifyUserId(roomMember['link']);
    ref.watch(chatInputProvider.notifier).messageTextMapMarkDown.addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$userId)',
    });
    ref.watch(chatInputProvider.notifier).messageTextMapHtml.addAll({
      '@$displayName': '<a href="https://matrix.to/#/$userId">$displayName</a>',
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
    return Offstage(
      offstage:
          !ref.watch(chatInputProvider.select((ci) => ci.attachmentVisible)),
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

  void onClickCamera(BuildContext context, WidgetRef ref) {
    ref.read(chatInputProvider.notifier).toggleAttachment();
    ref.read(chatRoomProvider.notifier).handleMultipleImageSelection(context);
  }

  void onClickFile(BuildContext context, WidgetRef ref) {
    ref.read(chatRoomProvider.notifier).handleFileSelection(context);
  }

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

  void onClick(BuildContext context, WidgetRef ref) {
    ref.read(chatRoomProvider.notifier).handleMultipleImageSelection(context);
  }
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
    return Offstage(
      offstage:
          !ref.watch(chatInputProvider.select((ci) => ci.emojiPickerVisible)),
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
    var notifier = ref.read(chatInputProvider.notifier);
    notifier.mentionKey.currentState!.controller!.text += emoji.emoji;
    notifier.showSendBtn(true);
  }

  void handleBackspacePressed() {
    var notifier = ref.read(chatInputProvider.notifier);
    notifier.mentionKey.currentState!.controller!.text = notifier
        .mentionKey.currentState!.controller!.text.characters
        .skipLast(1)
        .string;
    if (notifier.mentionKey.currentState!.controller!.text.isEmpty) {
      notifier.showSendBtn(false);
    }
  }
}
