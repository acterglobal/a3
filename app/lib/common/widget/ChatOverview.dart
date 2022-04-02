// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers

import 'dart:typed_data';

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatOverview extends StatelessWidget {
  final List<Room> rooms;

  const ChatOverview({Key? key, required this.rooms}) : super(key: key);

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
            ChatListItem(room: rooms[index]),
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

  const ChatListItem({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ToDo: UnreadCounter
    return ListTile(
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
                  color: Colors.white),
            );
          } else {
            return Text('Loading Name');
          }
        },
      ),
      subtitle: Container(
        margin: const EdgeInsets.only(
          top: 10,
        ),
        child: Text(
          'Hello',
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
        ),
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
