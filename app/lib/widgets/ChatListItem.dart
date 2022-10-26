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
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';

class ChatListItem extends StatefulWidget {
  final String userId;
  final Conversation room;
  final LatestMessage? latestMessage;
  final List<types.User> typingUsers;

  const ChatListItem({
    Key? key,
    required this.userId,
    required this.room,
    this.latestMessage,
    required this.typingUsers,
  }) : super(key: key);

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  Future<FfiBufferUint8>? avatar;
  String? displayName;

  @override
  void initState() {
    super.initState();

    widget.room.getProfile().then((value) {
      if (mounted) {
        setState(() {
          if (value.hasAvatar()) {
            avatar = value.getAvatar();
          }
          displayName = value.getDisplayName();
        });
      }
    });
  }

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
                  userId: widget.userId,
                  room: widget.room,
                ),
              ),
            );
          },
          leading: CustomAvatar(
            avatar: avatar,
            displayName: displayName,
            radius: 25,
            isGroup: true,
            stringName: simplifyRoomId(widget.room.getRoomId())!,
          ),
          title: buildTitle(context),
          subtitle: buildSubtitle(context),
          trailing: buildTrailing(context),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Divider(
            indent: 75,
            endIndent: 10,
            color: AppCommonTheme.dividerColor,
          ),
        ),
      ],
    );
  }

  Widget buildTitle(BuildContext context) {
    if (displayName == null) {
      return Text(
        AppLocalizations.of(context)!.loadingName,
        style: ChatTheme01.chatTitleStyle,
      );
    }
    return Text(
      displayName!,
      style: ChatTheme01.chatTitleStyle,
    );
  }

  Widget? buildSubtitle(BuildContext context) {
    if (widget.latestMessage == null) {
      if (widget.typingUsers.isEmpty) {
        return null;
      }
      return Text(
        getUserPlural(widget.typingUsers),
        style: ChatTheme01.latestChatStyle.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (widget.typingUsers.isEmpty != true) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          getUserPlural(widget.typingUsers),
          style: ChatTheme01.latestChatStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ParsedText(
        text:
            '${simplifyUserId(widget.latestMessage!.sender)}: ${widget.latestMessage!.body}',
        style: ChatTheme01.latestChatStyle,
        regexOptions: const RegexOptions(multiLine: true, dotAll: true),
        maxLines: 2,
        parse: [
          MatchText(
            pattern: '(\\*\\*|\\*)(.*?)(\\*\\*|\\*)',
            style: ChatTheme01.latestChatStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
            renderText: ({required String str, required String pattern}) {
              return {'display': str.replaceAll(RegExp('(\\*\\*|\\*)'), '')};
            },
          ),
          MatchText(
            pattern: '_(.*?)_',
            style: ChatTheme01.latestChatStyle.copyWith(
              fontStyle: FontStyle.italic,
            ),
            renderText: ({required String str, required String pattern}) {
              return {'display': str.replaceAll('_', '')};
            },
          ),
          MatchText(
            pattern: '~(.*?)~',
            style: ChatTheme01.latestChatStyle.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
            renderText: ({required String str, required String pattern}) {
              return {'display': str.replaceAll('~', '')};
            },
          ),
          MatchText(
            pattern: '`(.*?)`',
            style: ChatTheme01.latestChatStyle.copyWith(
              fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
            ),
            renderText: ({required String str, required String pattern}) {
              return {'display': str.replaceAll('`', '')};
            },
          ),
          MatchText(
            pattern: regexEmail,
            style: ChatTheme01.latestChatStyle.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
          MatchText(
            pattern: regexLink,
            style: ChatTheme01.latestChatStyle.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget? buildTrailing(BuildContext context) {
    if (widget.latestMessage == null) {
      return null;
    }
    return Text(
      DateFormat.Hm().format(
        DateTime.fromMillisecondsSinceEpoch(
          widget.latestMessage!.originServerTs,
          isUtc: true,
        ),
      ),
      style: ChatTheme01.latestChatDateStyle,
    );
  }

  String getUserPlural(List<types.User> authors) {
    if (authors.isEmpty) {
      return '';
    } else if (authors.length == 1) {
      return '${authors[0].firstName} is typing...';
    } else if (authors.length == 2) {
      return '${authors[0].firstName} and ${authors[1].firstName} is typing...';
    } else {
      return '${authors[0].firstName} and ${authors.length - 1} others typing...';
    }
  }
}
