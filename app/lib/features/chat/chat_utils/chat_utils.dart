import 'package:html/dom.dart';

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
  Element aTagElement,
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

String? getRoomIdFromLink(Uri uri) {
  // Match regex for matrix room link
  final urlRegexp = RegExp(
    r'https://matrix\.to/#/(?<roomId>.+):(?<server>.+)+',
    caseSensitive: false,
  );
  final matches = urlRegexp.firstMatch(uri.toString());

  //Link is type of matrix room link
  if (matches != null) {
    final roomId = matches.namedGroup('roomId');
    var server = matches.namedGroup('server');

    //Check & remove if string contains "?via=<server> pattern"
    server = server!.split('?via=').first;

    //Create complete roomId with home server information
    var roomIdWithServer = '$roomId:$server';

    //For public groups - Replace encoded '%23' string with #
    if (roomIdWithServer.startsWith('%23')) {
      roomIdWithServer = roomIdWithServer.replaceAll('%23', '#');
    }

    //Return roomId
    return roomIdWithServer;
  }

  //Link is other than matrix room link
  return null;
}
