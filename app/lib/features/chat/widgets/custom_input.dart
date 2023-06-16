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

  final Function()? onButtonPressed;
  final bool isChatScreen;
  final String roomName;

  const CustomChatInput({
    Key? key,
    required this.isChatScreen,
    this.onButtonPressed,
    required this.roomName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Size size = MediaQuery.of(context).size;
    final client = ref.watch(clientProvider);
    final chatRoom = ref.watch(chatRoomProvider);
    final chatInputState = ref.watch(chatInputProvider);
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: chatInputState.showReplyView,
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
                              client!.userId().toString() ==
                                      chatRoom.repliedToMessage!.author.id
                                  ? 'Replying to you'
                                  : 'Replying to ${toBeginningOfSentenceCase(chatRoom.repliedToMessage?.author.firstName)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (chatRoom.repliedToMessage != null &&
                                chatRoom.replyMessageWidget != null)
                              _ReplyContentWidget(
                                msg: chatRoom.repliedToMessage,
                                messageWidget: chatRoom.replyMessageWidget,
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
                                .setChatInputState(showReplyView: false);
                            ref
                                .read(chatRoomProvider.notifier)
                                .setChatRoomState(
                                  replyMessageWidget: const SizedBox.shrink(),
                                );
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
                      if (isChatScreen) const _BuildAttachmentBtn(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _TextInputWidget(
                            isChatScreen: isChatScreen,
                            roomName: roomName,
                          ),
                        ),
                      ),
                      if (chatInputState.isSendButtonVisible || !isChatScreen)
                        _BuildSendBtn(onButtonPressed: onButtonPressed),
                      if (!chatInputState.isSendButtonVisible && isChatScreen)
                        _BuildImageBtn(
                          roomName: roomName,
                        ),
                      if (!chatInputState.isSendButtonVisible && isChatScreen)
                        const SizedBox(width: 10),
                      if (!chatInputState.isSendButtonVisible && isChatScreen)
                        const _BuildAudioBtn(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        EmojiPickerWidget(size: size),
        AttachmentWidget(
          icons: _attachmentIcons,
          roomName: roomName,
          size: size,
        ),
      ],
    );
  }
}

class _BuildAttachmentBtn extends ConsumerWidget {
  const _BuildAttachmentBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(chatInputProvider.notifier).focusNode.unfocus();
        ref.read(chatInputProvider.notifier).focusNode.canRequestFocus = true;
        ref.read(chatInputProvider.notifier).setChatInputState(
              isEmojiContainerVisible: false,
              isAttachmentVisible: false,
            );
      },
      child: const _BuildPlusBtn(),
    );
  }
}

class _BuildPlusBtn extends ConsumerWidget {
  const _BuildPlusBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentVisible =
        ref.watch(chatInputProvider.select((e) => e.isAttachmentVisible));
    return Visibility(
      visible: attachmentVisible,
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
  const _TextInputWidget({
    required this.isChatScreen,
    required this.roomName,
  });
  final bool isChatScreen;
  final String roomName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatInputState = ref.watch(chatInputProvider.notifier);
    final chatRoomState = ref.watch(chatRoomProvider.notifier);
    return FlutterMentions(
      key: chatInputState.mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(roomMember, ref);
      },
      onChanged: (String value) {
        chatInputState.sendButtonUpdate();
        chatRoomState.typingNotice(true);
      },
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      maxLines:
          MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 2,
      minLines: 1,
      focusNode: chatInputState.focusNode,
      decoration: InputDecoration(
        isCollapsed: true,
        suffixIcon: InkWell(
          onTap: () {
            chatInputState.focusNode.unfocus();
            chatInputState.focusNode.canRequestFocus = true;
            chatInputState.setChatInputState(
              isAttachmentVisible: false,
              isEmojiVisible: false,
            );
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
        hintText: isChatScreen
            ? AppLocalizations.of(context)!.newMessage
            : '${AppLocalizations.of(context)!.messageTo} $roomName',
        contentPadding: const EdgeInsets.all(15),
        hintMaxLines: 1,
      ),
      mentions: [
        Mention(
          trigger: '@',
          data: ref.watch(chatInputProvider).mentionList,
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

  void _handleMentionAdd(
    Map<String, dynamic> roomMember,
    WidgetRef ref,
  ) {
    String userId = roomMember['link'];
    String displayName = roomMember.containsKey('display')
        ? roomMember['display']
        : simplifyUserId(roomMember['link']);
    Map<String, String> messageTextMapMarkDown = {};
    Map<String, String> messageTextMapHtml = {};
    messageTextMapMarkDown.addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$userId)',
    });
    messageTextMapHtml.addAll({
      '@$displayName': '<a href="https://matrix.to/#/$userId">$displayName</a>',
    });
    ref.read(chatInputProvider.notifier).setChatInputState(
          messageTextMapHtml: messageTextMapHtml,
          messageTextMapMarkDown: messageTextMapMarkDown,
        );
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
  final String roomName;
  final Size size;

  const AttachmentWidget({
    Key? key,
    required this.icons,
    required this.roomName,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentVisible =
        ref.watch(chatInputProvider.select((e) => e.isAttachmentVisible));
    return Offstage(
      offstage: !attachmentVisible,
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
                      onTap: () {
                        ref
                            .read(chatInputProvider.notifier)
                            .setChatInputState(isAttachmentVisible: false);
                        ref
                            .read(chatRoomProvider.notifier)
                            .handleMultipleImageSelection(
                              context,
                              roomName,
                            );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
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
                      onTap: () => ref
                          .read(chatRoomProvider.notifier)
                          .handleFileSelection(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Atlas.folder),
                          SizedBox(height: 6),
                          Text('File', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
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
}

class _BuildAudioBtn extends StatelessWidget {
  const _BuildAudioBtn();

  @override
  Widget build(BuildContext context) {
    return const Icon(Atlas.microphone);
  }
}

class _BuildImageBtn extends ConsumerWidget {
  const _BuildImageBtn({
    required this.roomName,
  });

  final String roomName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref
            .read(chatRoomProvider.notifier)
            .handleMultipleImageSelection(context, roomName);
      },
      child: const Icon(Atlas.camera_photo),
    );
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
  const _BuildSendBtn({
    required this.onButtonPressed,
  });

  final Function()? onButtonPressed;

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
    final emojiVisible =
        ref.watch(chatInputProvider.select((e) => e.isEmojiVisible));
    return Offstage(
      offstage: !emojiVisible,
      child: SizedBox(
        height: widget.size.height * 0.3,
        child: EmojiPicker(
          onEmojiSelected: _handleEmojiSelected,
          onBackspacePressed: _handleBackspacePressed,
          config: Config(
            columns: 7,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            initCategory: Category.SMILEYS,
            showRecentsTab: true,
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

  void _handleEmojiSelected(Category? category, Emoji emoji) {
    final chatInputState = ref.watch(chatInputProvider.notifier);
    chatInputState.mentionKey.currentState!.controller!.text += emoji.emoji;
    chatInputState.sendButtonUpdate();
  }

  void _handleBackspacePressed() {
    final chatInputState = ref.watch(chatInputProvider.notifier);
    chatInputState.mentionKey.currentState!.controller!.text = chatInputState
        .mentionKey.currentState!.controller!.text.characters
        .skipLast(1)
        .string;
    if (chatInputState.mentionKey.currentState!.controller!.text.isEmpty) {
      chatInputState.sendButtonUpdate();
    }
  }
}
