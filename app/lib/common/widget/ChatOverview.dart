// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers

import 'dart:typed_data';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatOverview extends StatelessWidget {
  final List<Room> rooms;
  final String userId;
  const ChatOverview({
    Key? key,
    required this.rooms,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.only(top: 10),
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: <Widget>[
            ChatListItem(
              room: rooms[index],
              userId: userId,
            ),
            Container(
              // margin: EdgeInsets.only(left: 70, bottom: 10, right: 10),
              child: Divider(
                indent: 75,
                endIndent: 15,
                height: 1,
                thickness: 0.5,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChatListItem extends StatelessWidget {
  final Room room;
  final String userId;
  const ChatListItem({Key? key, required this.room, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<types.Message> _messages = [];
    // ToDo: UnreadCounter
    return ListTile(
      enableFeedback: true,
      onTap: () {
        Navigator.pushNamed(context, '/chat');
      },
      // hoverColor: Colors.grey[700],
      // contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      leading: FutureBuilder<Uint8List>(
        future: room.avatar().then((fb) => fb.asTypedList()),
        // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 25,
              backgroundImage:
                  MemoryImage(Uint8List.fromList(snapshot.requireData)),
            );
          } else {
            return CircleAvatar(
              radius: 25,
              backgroundColor: Colors.brown.shade800,
              child: const Text('H'),
            );
          }
        },
      ),
      title: FutureBuilder<String>(
        future: room.displayName(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.requireData,
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
      subtitle: FutureBuilder<TimelineStream>(
        future: room.timeline(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              margin: const EdgeInsets.only(top: 10),
              child: Text(
                userId,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
      trailing: FutureBuilder<FfiListRoomMember>(
        future: room.activeMembers(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.requireData.length.toString(),
              style: TextStyle(color: Colors.white),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}
