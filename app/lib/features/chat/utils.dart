import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as html;
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:html/parser.dart';

class ChatUtils {
  //Check for mentioned user link
  static final mentionedUserLinkRegex = RegExp(
    r'https://matrix.to/#/(?<alias>@.+):(?<server>.+)',
  );

  static final matrixLinks = RegExp(
    '(matrix:|https://matrix.to/#/)([\\S]*)',
    caseSensitive: false,
  );

  static bool renderCustomMessageBubble(types.CustomMessage message) {
    switch (message.metadata?['eventType']) {
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical_alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history_visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned_events':
      case 'm.room.power_levels':
      case 'm.room.server_acl':
      case 'm.room.third_party_invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
      case 'm.poll.start':
        // supported if we have a body
        return message.metadata?['body'] != null;
      case 'm.room.member':
        if (message.metadata?['msgType'] == 'None') {
          // not a change we want to show
          return false;
        }
        return message.metadata?['body'] != null;
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
        // no support yet
        return false;
      case 'm.sticker':
      case 'm.room.redaction':
      case 'm.room.encrypted':
        // supported
        return true;
      case 'm.room.message':
        // special case of supporting locations
        return message.metadata?['msgType'] == 'm.location';
    }

    return false;
  }

  static String? extractUserIdFromUri(String link) {
    final mentionedUserLink = mentionedUserLinkRegex.firstMatch(link);

    if (mentionedUserLink != null) {
      //Get Username from mentioned user link
      final alias = mentionedUserLink.namedGroup('alias') ?? '';
      final server = mentionedUserLink.namedGroup('server') ?? '';
      return '$alias:$server';
    }
    return null;
  }

  static UserMentionMessageData parseUserMentionMessage(
    String message,
    html.Element aTagElement,
  ) {
    String msg = message;
    String userName = '';
    String displayName = '';

    // Get 'A Tag' href link
    final hrefLink = aTagElement.attributes['href'] ?? '';

    final mentionedUserLink = mentionedUserLinkRegex.firstMatch(hrefLink);

    if (mentionedUserLink != null) {
      //Get Username from mentioned user link
      final alias = mentionedUserLink.namedGroup('alias') ?? '';
      final server = mentionedUserLink.namedGroup('server') ?? '';
      userName = '$alias:$server';

      //Get Display name from mentioned user link
      displayName = aTagElement.text;

      // Replace displayName with @displayName
      msg = msg.replaceAll(
        aTagElement.outerHtml,
        displayName,
      );
    }
    return UserMentionMessageData(
      parsedMessage: msg,
      userName: userName,
      displayName: displayName,
    );
  }

  static String? getRoomIdFromLink(Uri uri) {
    final link = Uri.decodeFull(uri.toString());

    // Match regex for matrix room link
    final urlRegexp = RegExp(
      r'https://matrix\.to/#/(?<roomId>.+):(?<server>.+)+',
      caseSensitive: false,
    );
    final matches = urlRegexp.firstMatch(link);

    //Link is type of matrix room link
    if (matches != null) {
      final roomId = matches.namedGroup('roomId');
      var server = matches.namedGroup('server');

      //Check & remove if string contains "?via=<server> pattern"
      server = server!.split('?via=').first;

      //Create complete roomId with home server information
      var roomIdWithServer = '$roomId:$server';

      //Return roomId
      return roomIdWithServer;
    }

    //Link is other than matrix room link
    return null;
  }

  static Future<void> navigateToRoomOrAskToJoin(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    ///Get room from roomId
    final room = await ref.read(maybeRoomProvider(roomId).future);
    if (!context.mounted) return;

    /// Navigate to Room is already joined
    if (room != null && room.isJoined()) {
      //Navigate to Space
      if (room.isSpace()) {
        goToSpace(context, roomId);
      }
      //Navigate to Chat
      else {
        goToChat(context, roomId);
      }
    }

    /// Ask to join room if not yet joined
    else {
      askToJoinRoom(context, ref, roomId);
    }
  }

  static void askToJoinRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.of(context).youAreNotPartOfThisGroup,
            ),
            const SizedBox(height: 20),
            ActerPrimaryActionButton(
              onPressed: () async {
                Navigator.pop(context);
                final server = roomId.split(':').last;
                await joinRoom(
                  context,
                  ref,
                  L10n.of(context).tryingToJoin(roomId),
                  roomId,
                  server,
                  (roomId) => navigateToRoomOrAskToJoin(context, ref, roomId),
                );
              },
              child: Text(L10n.of(context).joinRoom),
            ),
          ],
        ),
      ),
    );
  }

  static String prepareMsg(MsgContent? content) {
    if (content == null) return '';
    final formatted = content.formattedBody();
    if (formatted != null) {
      return formatted;
    }
    final body = content.body();
    // replace all matrix-style links with a hrefs
    return body.replaceAllMapped(
      matrixLinks,
      (match) => '<a href="${match.group(0)}">${match.group(0)}</a>',
    );
  }

  static String parseEditMessage(types.Message message, WidgetRef ref) {
    final mentionNotifier = ref.read(chatInputProvider.notifier);
    String messageBodyText = '';
    if (message is types.TextMessage) {
      // Parse String Data to HTML document
      final document = parse(message.text);

      if (document.body != null) {
        // Get message data
        String msg = message.text.trim();

        // Get list of 'A Tags' values
        final aTagElementList = document.getElementsByTagName('a');

        for (final aTagElement in aTagElementList) {
          final userMentionMessageData =
              parseUserMentionMessage(msg, aTagElement);
          msg = userMentionMessageData.parsedMessage;

          // Update mentions data
          mentionNotifier.addMention(
            userMentionMessageData.displayName,
            userMentionMessageData.userName,
          );
        }

        // Parse data
        final messageDocument = parse(msg);
        messageBodyText = messageDocument.body?.text ?? '';
      }
    }
    return messageBodyText;
  }
}

class UserMentionMessageData {
  String parsedMessage;
  String userName;
  String displayName;

  UserMentionMessageData({
    required this.parsedMessage,
    required this.userName,
    required this.displayName,
  });
}
