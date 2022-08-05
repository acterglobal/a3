// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers

import 'dart:io';

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/common/widget/customAvatar.dart';
import 'package:effektio/screens/HomeScreens/ChatScreen.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 10),
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: <Widget>[
            ChatListItem(
              room: rooms[index],
              user: user,
            ),
            Divider(
              height: 1,
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
      leading: CustomAvatar(
        avatar: room.avatar(),
        displayName: room.displayName(),
        radius: 25,
        isGroup: true,
        stringName: '',
      ),
      title: FutureBuilder<String>(
        future: room.displayName(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.requireData,
              style: ChatTheme01.chatTitleStyle,
            );
          } else {
            return Text(AppLocalizations.of(context)!.loadingName);
          }
        },
      ),
      subtitle: FutureBuilder<RoomMessage>(
        future: room.latestMessage(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: ParsedText(
                text:
                    '${getNameFromId(snapshot.requireData.sender())}: ${snapshot.requireData.body()}',
                style: ChatTheme01.latestChatStyle,
                regexOptions: const RegexOptions(multiLine: true, dotAll: true),
                maxLines: 2,
                parse: [
                  MatchText(
                    pattern: '(\\*\\*|\\*)(.*?)(\\*\\*|\\*)',
                    style: ChatTheme01.latestChatStyle
                        .copyWith(fontWeight: FontWeight.bold),
                    renderText: ({
                      required String str,
                      required String pattern,
                    }) {
                      return {
                        'display': str.replaceAll(RegExp('(\\*\\*|\\*)'), '')
                      };
                    },
                  ),
                  MatchText(
                    pattern: '_(.*?)_',
                    style: ChatTheme01.latestChatStyle
                        .copyWith(fontStyle: FontStyle.italic),
                    renderText: ({
                      required String str,
                      required String pattern,
                    }) {
                      return {'display': str.replaceAll('_', '')};
                    },
                  ),
                  MatchText(
                    pattern: '~(.*?)~',
                    style: ChatTheme01.latestChatStyle.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                    renderText: ({
                      required String str,
                      required String pattern,
                    }) {
                      return {'display': str.replaceAll('~', '')};
                    },
                  ),
                  MatchText(
                    pattern: '`(.*?)`',
                    style: ChatTheme01.latestChatStyle.copyWith(
                      fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
                    ),
                    renderText: ({
                      required String str,
                      required String pattern,
                    }) {
                      return {'display': str.replaceAll('`', '')};
                    },
                  ),
                  MatchText(
                    pattern: regexEmail,
                    style: ChatTheme01.latestChatStyle
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                  MatchText(
                    pattern: regexLink,
                    style: ChatTheme01.latestChatStyle
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ],
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
              DateFormat.Hm().format(
                DateTime.fromMillisecondsSinceEpoch(
                  snapshot.requireData.originServerTs() * 1000,
                  isUtc: true,
                ),
              ),
              style: ChatTheme01.latestChatDateStyle,
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}
