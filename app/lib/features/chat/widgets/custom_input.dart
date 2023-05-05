import 'dart:convert';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

class CustomChatInput extends StatelessWidget {
  static const List<Icon> _attachmentIcons = [
    Icon(Atlas.camera_photo),
    Icon(Atlas.folder),
    Icon(Atlas.location),
  ];
  final ChatRoomController roomController;
  final Function()? onButtonPressed;
  final bool isChatScreen;
  final String roomName;

  const CustomChatInput({
    Key? key,
    required this.roomController,
    required this.isChatScreen,
    this.onButtonPressed,
    required this.roomName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        GetBuilder<ChatRoomController>(
          id: 'chat-input',
          builder: (ChatRoomController controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: controller.showReplyView,
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
                                  controller.isAuthor()
                                      ? 'Replying to you'
                                      : 'Replying to ${toBeginningOfSentenceCase(controller.repliedToMessage?.author.firstName)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (controller.repliedToMessage != null &&
                                    controller.replyMessageWidget != null)
                                  _ReplyContentWidget(
                                    msg: controller.repliedToMessage,
                                    messageWidget:
                                        controller.replyMessageWidget,
                                  ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                controller.showReplyView = false;
                                controller.replyMessageWidget = null;
                                controller.update(['chat-input']);
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
                          if (isChatScreen)
                            _BuildAttachmentBtn(controller: controller),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: _TextInputWidget(
                                isChatScreen: isChatScreen,
                                roomName: roomName,
                                controller: controller,
                              ),
                            ),
                          ),
                          if (controller.isSendButtonVisible || !isChatScreen)
                            _BuildSendBtn(onButtonPressed: onButtonPressed),
                          if (!controller.isSendButtonVisible && isChatScreen)
                            _BuildImageBtn(
                              roomName: roomName,
                              controller: controller,
                            ),
                          if (!controller.isSendButtonVisible && isChatScreen)
                            const SizedBox(width: 10),
                          if (!controller.isSendButtonVisible && isChatScreen)
                            const _BuildAudioBtn(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        EmojiPickerWidget(
          size: size,
          controller: roomController,
        ),
        AttachmentWidget(
          controller: roomController,
          icons: _attachmentIcons,
          roomName: roomName,
          size: size,
        ),
      ],
    );
  }
}

class _BuildAttachmentBtn extends StatelessWidget {
  const _BuildAttachmentBtn({required this.controller});

  final ChatRoomController controller;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        controller.isEmojiVisible.value = false;
        controller.isAttachmentVisible.value =
            !controller.isAttachmentVisible.value;
        controller.focusNode.unfocus();
        controller.focusNode.canRequestFocus = true;
      },
      child: _BuildPlusBtn(controller: controller),
    );
  }
}

class _BuildPlusBtn extends StatelessWidget {
  const _BuildPlusBtn({required this.controller});

  final ChatRoomController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Visibility(
        visible: controller.isAttachmentVisible.value,
        replacement: const Icon(Atlas.plus_circle),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Icon(Atlas.xmark_circle),
        ),
      ),
    );
  }
}

class _TextInputWidget extends StatelessWidget {
  const _TextInputWidget({
    required this.controller,
    required this.isChatScreen,
    required this.roomName,
  });
  final ChatRoomController controller;
  final bool isChatScreen;
  final String roomName;
  @override
  Widget build(BuildContext context) {
    return FlutterMentions(
      key: controller.mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(controller, roomMember);
      },
      onChanged: (String value) {
        controller.sendButtonUpdate();
        controller.typingNotice(true);
      },
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      maxLines:
          MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 2,
      minLines: 1,
      focusNode: controller.focusNode,
      decoration: InputDecoration(
        isCollapsed: true,
        suffixIcon: InkWell(
          onTap: () {
            controller.isAttachmentVisible.value = false;
            controller.isEmojiVisible.value = !controller.isEmojiVisible.value;
            controller.focusNode.unfocus();
            controller.focusNode.canRequestFocus = true;
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
          data: controller.mentionList,
          matchAll: false,
          suggestionBuilder: (Map<String, dynamic> roomMember) {
            return Container(
              color: Theme.of(context).colorScheme.neutral2,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.only(left: 50),
                leading: SizedBox(
                  width: 35,
                  height: 35,
                  child: UserAvatar(
                    uniqueKey: roomMember['link'],
                    radius: 20,
                    avatar: roomMember['avatar'],
                    isGroup: false,
                    stringName: roomMember['display'],
                  ),
                ),
                title: Text(
                  roomMember['display'],
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
    ChatRoomController controller,
    Map<String, dynamic> roomMember,
  ) {
    String userId = roomMember['link'];
    String displayName = roomMember['display'];
    controller.messageTextMapMarkDown.addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$userId)',
    });
    controller.messageTextMapHtml.addAll({
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

class AttachmentWidget extends StatelessWidget {
  final ChatRoomController controller;
  final List<Icon> icons;
  final String roomName;
  final Size size;

  const AttachmentWidget({
    Key? key,
    required this.controller,
    required this.icons,
    required this.roomName,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !controller.isAttachmentVisible.value,
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
                          controller.isAttachmentVisible.value = false;
                          controller.handleMultipleImageSelection(
                            context,
                            roomName,
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
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
                        onTap: () {
                          controller.handleFileSelection(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
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
                          children: const <Widget>[
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

class _BuildImageBtn extends StatelessWidget {
  const _BuildImageBtn({
    required this.controller,
    required this.roomName,
  });

  final String roomName;
  final ChatRoomController controller;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        controller.handleMultipleImageSelection(context, roomName);
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

class EmojiPickerWidget extends StatelessWidget {
  final ChatRoomController controller;
  final Size size;
  const EmojiPickerWidget({
    Key? key,
    required this.size,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !controller.isEmojiVisible.value,
        child: SizedBox(
          height: size.height * 0.3,
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
      ),
    );
  }

  void _handleEmojiSelected(Category? category, Emoji emoji) {
    controller.mentionKey.currentState!.controller!.text += emoji.emoji;
    controller.sendButtonUpdate();
  }

  void _handleBackspacePressed() {
    controller.mentionKey.currentState!.controller!.text = controller
        .mentionKey.currentState!.controller!.text.characters
        .skipLast(1)
        .string;
    if (controller.mentionKey.currentState!.controller!.text.isEmpty) {
      controller.sendButtonUpdate();
    }
  }
}
