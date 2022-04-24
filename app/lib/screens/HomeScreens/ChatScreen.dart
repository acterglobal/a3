// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_final_fields, prefer_typing_uninitialized_variables

import 'dart:typed_data';

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/store/chatTheme.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/common/widget/emptyMessagesPlaceholder.dart';
import 'package:effektio/repository/client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';

class ChatScreen extends StatefulWidget {
  final Conversation room;
  final String? user;
  const ChatScreen({Key? key, required this.room, required this.user})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late final _user;
  bool isLoading = false;
  // int _page = 0;
  @override
  void initState() {
    _user = types.User(
      id: widget.user!,
      firstName: getNameFromId(widget.user!),
    );
    _getMessages();
    super.initState();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _handleAtachmentPressed() {
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
                    Navigator.pop(context);
                    _handleImageSelection();
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
                    Navigator.pop(context);
                    _handleFileSelection();
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

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: randomString(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleFileSelection() async {
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

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  void _getMessages() async {
    setState(() {
      isLoading = true;
    });
    var stream = await widget.room.timeline();
    List<types.Message> messages = await getMessages(stream, 10);
    setState(() {
      _messages = messages;
      isLoading = false;
    });
  }

  // Future<void> _handleEndReached() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   var stream = await getTimeline(widget.room);
  //   List<types.Message> messages = await getMessages(stream, 10);
  //   setState(() {
  //     _messages = [..._messages, ...messages];
  //     _page = _page + 1;
  //     isLoading = false;
  //   });
  // }
  // Widget _bubbleBuilder(
  //   Widget child, {
  //   required message,
  //   required nextMessageInGroup,
  // }) {
  //   return Bubble(
  //     child: child,
  //     color: _user.id != message.author.id ||
  //             message.type == types.MessageType.image
  //         ? const Color(0xfff5f5f7)
  //         : AppColors.primaryColor,
  //     margin: nextMessageInGroup
  //         ? const BubbleEdges.symmetric(horizontal: 6)
  //         : null,
  //     nip: nextMessageInGroup
  //         ? BubbleNip.no
  //         : _user.id != message.author.id
  //             ? BubbleNip.leftBottom
  //             : BubbleNip.rightBottom,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(36, 38, 50, 1),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromRGBO(51, 53, 64, 0.4),
        elevation: 1,
        leadingWidth: MediaQuery.of(context).size.width,
        toolbarHeight: 70,
        leading: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset('assets/images/back_button.svg'),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
                    '${snapshot.requireData.length.toString()} Members',
                    style: GoogleFonts.montserrat(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  );
                } else {
                  return Container(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 70,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FutureBuilder<Uint8List>(
              future: widget.room.avatar().then((fb) => fb.asTypedList()),
              // a previously-obtained Future<String> or null
              builder:
                  (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
                if (snapshot.hasData) {
                  return CircleAvatar(
                    radius: 20,
                    backgroundImage: MemoryImage(
                      Uint8List.fromList(snapshot.requireData),
                      scale: 0.5,
                    ),
                  );
                } else {
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[600],
                    child: SvgPicture.asset(
                      'assets/images/people.svg',
                      width: 20,
                      height: 20,
                    ),
                  );
                }
              },
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
                    color: AppColors.primaryColor,
                  ),
                ),
              )
            : Chat(
                messages: _messages,
                onSendPressed: _handleSendPressed,
                user: _user,
                // isAttachmentUploading: true,
                avatarBuilder: (userId) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      radius: 15,
                      child: Text(getNameFromId(userId)[0].toUpperCase()),
                    ),
                  );
                },
                // bubbleBuilder: _bubbleBuilder,
                // showUserNames: true,
                showUserAvatars: true,
                onAttachmentPressed: _handleAtachmentPressed,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onMessageTap: _handleMessageTap,
                // onEndReached: _handleEndReached,
                // onEndReachedThreshold: 1,
                emptyState: EmptyPlaceholder(),
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
