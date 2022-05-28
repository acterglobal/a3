// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_final_fields, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:io';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/store/chatTheme.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/common/widget/customAvatar.dart';
import 'package:effektio/common/widget/emptyMessagesPlaceholder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Conversation,
        TimelineStream,
        RoomMessage,
        ImageDescription,
        FfiListMember;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:mutex/mutex.dart';
import 'package:open_file/open_file.dart';
import 'package:string_validator/string_validator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:themed/themed.dart';

class ChatScreen extends StatefulWidget {
  final Conversation room;
  final String? user;
  const ChatScreen({Key? key, required this.room, required this.user})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

final mtx = Mutex(); // acquire this mutex, when updating state

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late final _user;
  TimelineStream? _stream;
  bool isLoading = false;
  int _page = 0;

  @override
  void initState() {
    _user = types.User(
      id: widget.user!,
    );
    isLoading = true;
    super.initState();
    _getTimeline().whenComplete(
      () => {_handleEndReached(), _newEvent()},
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _insertMessage(types.ImageMessage m) {
    for (var i = 0; i < _messages.length; i++) {
      if (_messages[i].createdAt! < m.createdAt!) {
        _messages.insert(i, m);
        return;
      }
    }
    _messages.add(m);
  }

  Future<void> _getTimeline() async {
    await mtx.acquire();
    _stream = await widget.room.timeline();
    var messages = await _stream!.paginateBackwards(10);
    for (RoomMessage message in messages) {
      String msgtype = message.msgtype();
      if (msgtype == 'm.audio') {
      } else if (msgtype == 'm.emote') {
      } else if (msgtype == 'm.file') {
      } else if (msgtype == 'm.image') {
        message.imageBinary().then((binary) async {
          ImageDescription description = message.imageDescription();
          types.ImageMessage m = types.ImageMessage(
            author: types.User(id: message.sender()),
            createdAt: message.originServerTs() * 1000,
            height: description.height()?.toDouble(),
            id: message.eventId(),
            metadata: {
              'binary': binary.asTypedList(),
            },
            name: description.name(),
            size: description.size(),
            uri: '',
            width: description.width()?.toDouble(),
          );
          await mtx.acquire();
          setState(() {
            _insertMessage(m);
          });
          mtx.release();
        });
      } else if (msgtype == 'm.location') {
      } else if (msgtype == 'm.notice') {
      } else if (msgtype == 'm.server_notice') {
      } else if (msgtype == 'm.text') {
        types.TextMessage m = types.TextMessage(
          author: types.User(id: message.sender()),
          createdAt: message.originServerTs() * 1000,
          id: message.eventId(),
          text: message.body(),
        );
        _messages.add(m);
      } else if (msgtype == 'm.video') {
      } else if (msgtype == 'm.key.verification.request') {}
    }
    setState(() {
      isLoading = false;
    });
    if (_messages.isNotEmpty) {
      if (_messages.first.author.id == _user.id) {
        bool isSeen = await widget.room.readReceipt(_messages.first.id);
        types.TextMessage lm = types.TextMessage(
          author: _user,
          id: _messages.first.id,
          text: messages.first.body(),
          showStatus: true,
          status: isSeen ? Status.seen : Status.delivered,
        );
        _messages.removeAt(0);
        _messages.insert(0, lm);
      }
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
    mtx.release();
  }

  //will detect if any new event is arrived and will re-render the screen
  void _newEvent() async {
    await _stream!.next();
    var newEvent = await widget.room.latestMessage();
    final user = types.User(
      id: newEvent.sender(),
    );
    if (newEvent.sender() != _user.id) {
      final textMessage = types.TextMessage(
        id: newEvent.eventId(),
        author: user,
        text: newEvent.body(),
      );
      _messages.insert(0, textMessage);
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  //push messages in conversation
  void _handleSendPressed(types.PartialText message) async {
    await widget.room.typingNotice(false);
    var eventId = await widget.room.sendPlainMessage(message.text);
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: eventId,
      text: message.text,
      status: Status.sent,
      showStatus: true,
    );
    _messages.insert(0, textMessage);
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 124,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    _handleImageSelection(context);
                  },
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/images/camera.svg'),
                      ),
                      SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Photo',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _handleFileSelection(context);
                  },
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/images/document.svg'),
                      ),
                      SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'File',
                          style: TextStyle(
                            color: Colors.white,
                          ),
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

  void _handleImageSelection(BuildContext context) async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final mimeType = lookupMimeType(result.path);
      var eventId = await widget.room.sendImageMessage(
        'Image placeholder',
        result.path,
        result.name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
      );

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: eventId,
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );
      Navigator.pop(context);
      setState(() {
        _messages.insert(0, message);
      });
    }
  }

  void _handleFileSelection(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('The File that is uploaded isn\'t sent to the server.'),
        ),
      );
      Navigator.pop(context);
      setState(() {
        _messages.insert(0, message);
      });
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  //Pagination Control
  Future<void> _handleEndReached() async {
    final messages = await _stream!.paginateBackwards(10);
    final List<types.Message> nextMessages = [];
    for (RoomMessage message in messages) {
      types.TextMessage m = types.TextMessage(
        author: types.User(id: message.sender()),
        id: message.eventId(),
        text: message.body(),
      );
      nextMessages.add(m);
    }
    setState(() {
      _messages = [..._messages, ...nextMessages];
      _page = _page + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppCommonTheme.backgroundColor,
        elevation: 1,
        centerTitle: true,
        toolbarHeight: 70,
        leading: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset(
                'assets/images/back_button.svg',
                color: AppCommonTheme.svgIconColor,
              ),
            ),
          ],
        ),
        title: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: widget.room.displayName(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.requireData,
                    overflow: TextOverflow.clip,
                    style: ChatTheme01.chatTitleStyle,
                  );
                } else {
                  return Text('Loading Name');
                }
              },
            ),
            SizedBox(height: 5),
            FutureBuilder<FfiListMember>(
              future: widget.room.activeMembers(),
              builder: (
                BuildContext context,
                AsyncSnapshot<FfiListMember> snapshot,
              ) {
                if (snapshot.hasData) {
                  return Text(
                    '${snapshot.requireData.length.toString()} ${AppLocalizations.of(context)!.emptyPlaceholderText}',
                    style:
                        ChatTheme01.chatBodyStyle + AppCommonTheme.primaryColor,
                  );
                } else {
                  return Container(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      color: AppCommonTheme.primaryColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              height: 45,
              width: 45,
              child: FittedBox(
                fit: BoxFit.contain,
                child: CustomAvatar(
                  avatar: widget.room.avatar(),
                  displayName: widget.room.displayName(),
                  radius: 20,
                  isGroup: true,
                  stringName: '',
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: isLoading
            ? Center(
                child: Container(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                    color: AppCommonTheme.primaryColor,
                  ),
                ),
              )
            : Chat(
                l10n: ChatL10nEn(
                  emptyChatPlaceholder: '',
                  attachmentButtonAccessibilityLabel: '',
                  fileButtonAccessibilityLabel: '',
                  inputPlaceholder: AppLocalizations.of(context)!.message,
                  sendButtonAccessibilityLabel: '',
                ),
                messages: _messages,
                onSendPressed: _handleSendPressed,
                user: _user,
                //custom avatar builder
                avatarBuilder: (userId) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomAvatar(
                      avatar: widget.room.avatar(),
                      displayName: null,
                      radius: 15,
                      isGroup: false,
                      stringName: getNameFromId(userId),
                    ),
                  );
                },
                // custom image builder for binary data
                imageMessageBuilder: (
                  imageMessage, {
                  required int messageWidth,
                }) {
                  if (imageMessage.uri.isEmpty) {
                    // binary data
                    return Image.memory(
                      imageMessage.metadata?['binary'],
                      width: messageWidth.toDouble(),
                    );
                  } else if (isURL(imageMessage.uri)) {
                    // remote url
                    return Image.network(
                      imageMessage.uri,
                      width: messageWidth.toDouble(),
                    );
                  } else {
                    // local path
                    // the image that just sent is displayed from local not remote
                    return Image.file(
                      File(imageMessage.uri),
                      width: messageWidth.toDouble(),
                    );
                  }
                },
                //Whenever users starts typing on keyboard, this will trigger the function
                onTextChanged: (text) async {
                  await widget.room.typingNotice(true);
                },
                showUserAvatars: true,
                onAttachmentPressed: _handleAttachmentPressed,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onMessageTap: _handleMessageTap,
                onEndReached: _handleEndReached,
                onEndReachedThreshold: 0.75,
                emptyState: EmptyPlaceholder(),
                //Custom Theme class, see lib/common/store/chatTheme.dart
                theme: EffektioChatTheme(
                  attachmentButtonIcon:
                      SvgPicture.asset('assets/images/attachment.svg'),
                  sendButtonIcon:
                      SvgPicture.asset('assets/images/sendIcon.svg'),
                  seenIcon: SvgPicture.asset('assets/images/seenIcon.svg'),
                  deliveredIcon: SvgPicture.asset('assets/images/sentIcon.svg'),
                ),
              ),
      ),
    );
  }
}
