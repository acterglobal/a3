// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers

import 'dart:io';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:intl/intl.dart';

class ChatListItem extends StatefulWidget {
  final Conversation room;

  final Client client;
  final LatestMessage? latestMessage;

  const ChatListItem({
    Key? key,
    required this.room,
    required this.client,
    this.latestMessage,
  }) : super(key: key);

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  late Future<String> displayName;

  @override
  void initState() {
    super.initState();
    displayName = getDisplayName();
  }

  Future<String> getDisplayName() async => await widget.room.displayName();

  @override
  Widget build(BuildContext context) {
    // ToDo: UnreadCounter
    return Column(
      children: <Widget>[
        ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  room: widget.room,
                  client: widget.client,
                ),
              ),
            );
          },
          leading: CustomAvatar(
            avatar: widget.room.avatar(),
            displayName: displayName,
            radius: 25,
            isGroup: true,
            stringName: '',
          ),
          title: FutureBuilder<String>(
            future: displayName,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return Text(
                  snapshot.requireData,
                  style: ChatTheme01.chatTitleStyle,
                );
              } else {
                return Text(
                  AppLocalizations.of(context)!.loadingName,
                  style: ChatTheme01.chatTitleStyle,
                );
              }
            },
          ),
          subtitle: buildSubtitle(context),
          trailing: buildTrailing(context),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: const Divider(
            indent: 75,
            endIndent: 10,
            color: AppCommonTheme.dividerColor,
          ),
        ),
      ],
    );
  }

  Widget buildSubtitle(BuildContext context) {
    if (widget.latestMessage == null) {
      return const SizedBox();
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ParsedText(
        text:
            '${getNameFromId(widget.latestMessage!.sender)}: ${widget.latestMessage!.body}',
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

  Widget buildTrailing(BuildContext context) {
    if (widget.latestMessage == null) {
      return const SizedBox();
    }
    return Text(
      DateFormat.Hm().format(
        DateTime.fromMillisecondsSinceEpoch(
          widget.latestMessage!.originServerTs * 1000,
          isUtc: true,
        ),
      ),
      style: ChatTheme01.latestChatDateStyle,
    );
  }
}
