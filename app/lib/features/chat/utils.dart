import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/rooms.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:html/dom.dart' as html;
import 'package:flutter_gen/gen_l10n/l10n.dart';

final chatRoomUriMatcher = RegExp('/chat/.+');

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

UserMentionMessageData parseUserMentionMessage(
  String message,
  html.Element aTagElement,
) {
  String msg = message;
  String userName = '';
  String displayName = '';

  // Get 'A Tag' href link
  final hrefLink = aTagElement.attributes['href'] ?? '';

  //Check for mentioned user link
  final mentionedUserLinkRegex = RegExp(
    r'https://matrix.to/#/(?<alias>.+):(?<server>.+)',
  );

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

/// helper to figure out how to route to the specific chat
void goToChat(String roomId) {
  final context = rootNavKey.currentContext!;
  final currentUri = context.read(currentRoutingLocation);
  if (!currentUri.startsWith(chatRoomUriMatcher)) {
    // we are not in a chat room. just a regular push routing
    // will do
    context.pushNamed(Routes.chatroom.name, pathParameters: {'roomId': roomId});
    return;
  }

  // we are in a chat page
  if (roomId == rootNavKey.currentContext!.read(selectedChatIdProvider)) {
    // we are on the same page, nothing to be done
    return;
  }

  // we are on a different chat page. Push replace the current screen
  context.pushReplacementNamed(
    Routes.chatroom.name,
    pathParameters: {'roomId': roomId},
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
      context.pushNamed(
        Routes.space.name,
        pathParameters: {'spaceId': room.roomIdStr()},
      );
    }
    //Navigate to Chat
    else {
      context.goNamed(
        Routes.chatroom.name,
        pathParameters: {'roomId': room.roomIdStr()},
      );
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
