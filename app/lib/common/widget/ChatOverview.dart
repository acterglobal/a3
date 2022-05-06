// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers

import 'dart:typed_data';

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/screens/HomeScreens/ChatScreen.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatOverview extends StatelessWidget {
  final List<Conversation> rooms;
  final String? user;
  const ChatOverview({
    Key? key,
    required this.rooms,
    required this.user,
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
              user: user,
            ),
            Container(
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
  final Conversation room;
  final String? user;
  const ChatListItem({Key? key, required this.room, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ToDo: UnreadCounter
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              room: room,
              user: user,
            ),
          ),
        );
      },
      leading: FutureBuilder<Uint8List>(
        future: room.avatar().then((fb) => fb.asTypedList()),
        // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          } else {
            if (snapshot.hasData) {
              return CircleAvatar(
                radius: 25,
                backgroundImage:
                    MemoryImage(Uint8List.fromList(snapshot.requireData)),
              );
            } else {
              return CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[700],
                child: SvgPicture.asset('assets/images/people.svg'),
              );
            }
          }
        },
      ),
      title: FutureBuilder<String>(
        future: room.displayName(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.requireData,
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
      subtitle: FutureBuilder<RoomMessage>(
        future: room.latestMessage(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                '${getNameFromId(snapshot.requireData.sender())}: ${snapshot.requireData.body()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
                maxLines: 2,
              ),
            );
          } else {
            return Container();
          }
        },
      ),
      trailing: FutureBuilder<RoomMessage>(
        future: room.latestMessage(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              formatedTime(snapshot.requireData.originServerTs())!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}
