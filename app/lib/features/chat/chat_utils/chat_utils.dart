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
