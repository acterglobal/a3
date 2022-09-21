// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers

import 'dart:io';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/common/widget/customAvatar.dart';
import 'package:effektio/screens/HomeScreens/ChatScreen.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:intl/intl.dart';

class RecentMessage {
  String sender;
  String body;
  int originServerTs;

  RecentMessage({
    required this.sender,
    required this.body,
    required this.originServerTs,
  });
}

class ChatListItem extends StatefulWidget {
  final Conversation room;
  final String user;
  final RecentMessage? recentMessage;

  const ChatListItem({
    Key? key,
    required this.room,
    required this.user,
    this.recentMessage,
  }) : super(key: key);

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  @override
  Widget build(BuildContext context) {
    // ToDo: UnreadCounter
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              room: widget.room,
              user: widget.user,
            ),
          ),
        );
      },
      leading: CustomAvatar(
        avatar: widget.room.avatar(),
        displayName: widget.room.displayName(),
        radius: 25,
        isGroup: true,
        stringName: '',
      ),
      title: FutureBuilder<String>(
        future: widget.room.displayName(),
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
      subtitle: buildSubtitle(context),
      trailing: buildTraining(context),
    );
  }

  Widget buildSubtitle(BuildContext context) {
    if (widget.recentMessage == null) {
      return SizedBox();
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ParsedText(
        text:
            '${getNameFromId(widget.recentMessage!.sender)}: ${widget.recentMessage!.body}',
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
              return {'display': str.replaceAll(RegExp('(\\*\\*|\\*)'), '')};
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
  }

  Widget buildTraining(BuildContext context) {
    if (widget.recentMessage == null) {
      return SizedBox();
    }
    return Text(
      DateFormat.Hm().format(
        DateTime.fromMillisecondsSinceEpoch(
          widget.recentMessage!.originServerTs * 1000,
          isUtc: true,
        ),
      ),
      style: ChatTheme01.latestChatDateStyle,
    );
  }
}
