import 'dart:io';
import 'dart:math';

import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatProfile.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:effektio/widgets/EmptyHistoryPlaceholder.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Conversation, FfiBufferUint8, FfiListMember, UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:string_validator/string_validator.dart';
import 'package:themed/themed.dart';
import 'package:transparent_image/transparent_image.dart';

class ChatScreen extends StatefulWidget {
  final Conversation room;
  final String userId;

  const ChatScreen({
    Key? key,
    required this.room,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Future<FfiBufferUint8>? roomAvatar;
  String? roomName;
  Map<String, Future<FfiBufferUint8>> userAvatars = {};
  Map<String, String> userNames = {};
  ChatRoomController roomController = Get.find<ChatRoomController>();
  ChatListController listController = Get.find<ChatListController>();

  @override
  void initState() {
    super.initState();

    roomController.setCurrentRoom(widget.room);
    widget.room.getProfile().then((value) {
      if (mounted) {
        setState(() {
          if (value.hasAvatar()) {
            roomAvatar = value.getAvatar();
          }
          roomName = value.getDisplayName();
        });
      }
    });
    widget.room.activeMembers().then((members) async {
      Map<String, Future<FfiBufferUint8>> avatars = {};
      Map<String, String> names = {};
      for (var member in members) {
        String userId = member.userId();
        UserProfile userProfile = await member.getProfile();
        if (userProfile.hasAvatar()) {
          avatars[userId] = userProfile.getAvatar();
        }
        String? name = userProfile.getDisplayName();
        if (name != null) {
          names[userId] = name;
        }
      }
      if (mounted) {
        setState(() {
          userAvatars = avatars;
          userNames = names;
        });
      }
    });
  }

  @override
  void dispose() {
    roomController.setCurrentRoom(null);

    super.dispose();
  }

  void handleAttachmentPressed(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 124,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => roomController.handleImageSelection(context),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset('assets/images/camera.svg'),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          AppLocalizations.of(context)!.photo,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => roomController.handleFileSelection(context),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset('assets/images/document.svg'),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          AppLocalizations.of(context)!.file,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget avatarBuilder(String userId) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        height: 28,
        width: 28,
        child: CustomAvatar(
          avatar: userAvatars[userId],
          displayName: userNames[userId],
          radius: 15,
          isGroup: false,
          stringName: simplifyUserId(userId)!,
        ),
      ),
    );
  }

  Widget textMessageBuilder(
    types.TextMessage p1, {
    required int messageWidth,
    required bool showName,
  }) {
    return Container(
      width: sqrt(
            p1.metadata!['messageLength'],
          ) *
          38.5,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 57),
      child: Html(
        // ignore: prefer_single_quotes, unnecessary_string_interpolations
        data: """${p1.text}""",
        style: {
          'body': Style(color: Colors.white),
          'a': Style(textDecoration: TextDecoration.none)
        },
      ),
    );
  }

  Widget imageMessageBuilder(
    types.ImageMessage imageMessage, {
    required int messageWidth,
  }) {
    if (imageMessage.uri.isEmpty) {
      // binary data
      if (imageMessage.metadata?.containsKey('binary') ?? false) {
        return CachedMemoryImage(
          uniqueKey: imageMessage.id,
          bytes: imageMessage.metadata?['binary'],
          width: messageWidth.toDouble(),
          placeholder: const CircularProgressIndicator(
            color: AppCommonTheme.primaryColor,
          ),
        );
      }
      return CachedMemoryImage(
        uniqueKey: UniqueKey().toString(),
        bytes: kTransparentImage,
        width: messageWidth.toDouble(),
      );
    }
    if (isURL(imageMessage.uri)) {
      // remote url
      return CachedNetworkImage(
        imageUrl: imageMessage.uri,
        width: messageWidth.toDouble(),
      );
    }
    // local path
    // the image that just sent is displayed from local not remote
    return Image.file(
      File(imageMessage.uri),
      width: messageWidth.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          resizeToAvoidBottomInset: orientation == Orientation.portrait,
          appBar: AppBar(
            backgroundColor: AppCommonTheme.backgroundColor,
            elevation: 1,
            centerTitle: true,
            toolbarHeight: 70,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: SvgPicture.asset(
                'assets/images/back_button.svg',
                color: AppCommonTheme.svgIconColor,
              ),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildRoomName(context),
                const SizedBox(height: 5),
                buildActiveMembers(),
              ],
            ),
            actions: [
              buildProfileAction(),
            ],
          ),
          body: Obx(
            () => SafeArea(
              bottom: false,
              child: buildBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget buildProfileAction() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatProfileScreen(
              room: widget.room,
              isGroup: true,
              isAdmin: true,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: SizedBox(
          height: 45,
          width: 45,
          child: FittedBox(
            fit: BoxFit.contain,
            child: CustomAvatar(
              avatar: roomAvatar,
              displayName: roomName,
              radius: 20,
              isGroup: true,
              stringName: simplifyRoomId(widget.room.getRoomId())!,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRoomName(BuildContext context) {
    if (roomName == null) {
      return Text(AppLocalizations.of(context)!.loadingName);
    }
    return Text(
      roomName!,
      overflow: TextOverflow.clip,
      style: ChatTheme01.chatTitleStyle,
    );
  }

  Widget buildActiveMembers() {
    return FutureBuilder<FfiListMember>(
      future: widget.room.activeMembers(),
      builder: (BuildContext context, AsyncSnapshot<FfiListMember> snapshot) {
        if (snapshot.hasData) {
          return Text(
            '${snapshot.requireData.length} ${AppLocalizations.of(context)!.members}',
            style: ChatTheme01.chatBodyStyle + AppCommonTheme.primaryColor,
          );
        }
        return const SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
        );
      },
    );
  }

  Widget buildBody(BuildContext context) {
    if (roomController.isLoading.isTrue) {
      return const Center(
        child: SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
        ),
      );
    }
    int invitedIndex = listController.invitations.indexWhere((x) {
      return x.roomId() == widget.room.getRoomId();
    });
    return GetBuilder<ChatRoomController>(
      id: 'Chat',
      builder: (ChatRoomController controller) {
        return Stack(
          children: [
            Chat(
              customBottomWidget: CustomChatInput(
                isChatScreen: true,
                roomName: roomName ?? AppLocalizations.of(context)!.noName,
                onButtonPressed: () async {
                  String _text =
                      controller.mentionKey.currentState!.controller!.text;
                  controller.messageTextMap.forEach((key, value) {
                    _text = _text.replaceAll(key, value);
                  });
                  await controller.handleSendPressed(_text);
                  controller.messageTextMap.clear();
                  controller.mentionKey.currentState!.controller!.clear();
                  controller.sendButtonUpdate();
                },
              ),
              textMessageBuilder: textMessageBuilder,
              l10n: ChatL10nEn(
                emptyChatPlaceholder: '',
                attachmentButtonAccessibilityLabel: '',
                fileButtonAccessibilityLabel: '',
                inputPlaceholder: AppLocalizations.of(context)!.message,
                sendButtonAccessibilityLabel: '',
              ),
              messages: controller.messages,
              typingIndicatorOptions: TypingIndicatorOptions(
                customTypingIndicator: buildTypingIndicator(),
              ),
              onSendPressed: (_) {},
              user: types.User(id: widget.userId),
              // if invited, disable image gallery
              disableImageGallery: invitedIndex != -1,
              //custom avatar builder
              avatarBuilder: avatarBuilder,
              imageMessageBuilder: imageMessageBuilder,
              showUserAvatars: true,
              onAttachmentPressed: () => handleAttachmentPressed(context),
              onPreviewDataFetched: controller.handlePreviewDataFetched,
              onMessageTap: controller.handleMessageTap,
              onEndReached:
                  invitedIndex != -1 ? null : controller.handleEndReached,
              onEndReachedThreshold: 0.75,
              emptyState: const EmptyHistoryPlaceholder(),
              //Custom Theme class, see lib/common/store/chatTheme.dart
              theme: EffektioChatTheme(
                attachmentButtonIcon:
                    SvgPicture.asset('assets/images/attachment.svg'),
                sendButtonIcon: SvgPicture.asset('assets/images/sendIcon.svg'),
                seenIcon: SvgPicture.asset('assets/images/seenIcon.svg'),
                deliveredIcon: SvgPicture.asset('assets/images/sentIcon.svg'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildTypingIndicator() {
    return GetBuilder<ChatRoomController>(
      id: 'typing indicator',
      builder: (ChatRoomController controller) {
        return TypeIndicator(
          bubbleAlignment: BubbleRtlAlignment.right,
          showIndicator: controller.typingUsers.isNotEmpty,
          options: TypingIndicatorOptions(
            animationSpeed: const Duration(milliseconds: 800),
            typingUsers: controller.typingUsers,
            typingMode: TypingIndicatorMode.text,
          ),
        );
      },
    );
  }
}
