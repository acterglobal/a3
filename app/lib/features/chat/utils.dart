import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/rooms.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as html;
import 'package:flutter_gen/gen_l10n/l10n.dart';

//Check for mentioned user link
final mentionedUserLinkRegex = RegExp(
  r'https://matrix.to/#/(?<alias>@.+):(?<server>.+)',
);

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

String? extractUserIdFromUri(String link) {
  final mentionedUserLink = mentionedUserLinkRegex.firstMatch(link);

  if (mentionedUserLink != null) {
    //Get Username from mentioned user link
    final alias = mentionedUserLink.namedGroup('alias') ?? '';
    final server = mentionedUserLink.namedGroup('server') ?? '';
    return '$alias:$server';
  }
  return null;
}

UserMentionMessageData parseUserMentionMessage(
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
      '@$displayName',
    );
  }
  return UserMentionMessageData(
    parsedMessage: msg,
    userName: userName,
    displayName: displayName,
  );
}

String? getRoomIdFromLink(Uri uri) {
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

Future<void> navigateToRoomOrAskToJoin(
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

void askToJoinRoom(
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
    builder: (ctx) => Container(
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
              Navigator.of(context).pop();
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
