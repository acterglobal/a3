// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_final_fields, prefer_typing_uninitialized_variables

import 'dart:math';
import 'dart:typed_data';

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/repository/client.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final Room room;
  final String? user;
  const ChatScreen({Key? key, required this.room, required this.user})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late final _user;

  @override
  void initState() {
    _user = types.User(id: widget.user!);
    super.initState();
    _getMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
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

  void _getMessages() async {
    final stream = await getTimeline(widget.room);
    await getMessages(stream, 20).then(
      (messages) => {
        setState(() {
          _messages = messages;
        })
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(36, 38, 50, 1),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromRGBO(36, 38, 50, 1),
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
                    style: GoogleFonts.montserrat(
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
            FutureBuilder<FfiListRoomMember>(
              future: widget.room.activeMembers(),
              builder: (BuildContext context,
                  AsyncSnapshot<FfiListRoomMember> snapshot) {
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
                        scale: 0.5),
                  );
                } else {
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors
                        .primaries[Random().nextInt(Colors.primaries.length)],
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
        child: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
          showUserAvatars: true,
        ),
      ),
    );
  }
}
