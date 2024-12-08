import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/room/actions/show_room_preview.dart';
import 'package:acter/features/deep_linking/actions/handle_deep_link_uri.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart';

//Check for mentioned user link
final mentionedUserLinkRegex =
    RegExp(r'https://matrix.to/#/(?<alias>@.+):(?<server>.+)');

bool renderCustomMessageBubble(types.CustomMessage message) {
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
    msg = msg.replaceAll(aTagElement.outerHtml, displayName);
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
    showRoomPreview(context: context, ref: ref, roomIdOrAlias: roomId);
  }
}

final matrixLinks = RegExp(
  '(matrix:|https://matrix.to/#/)([\\S]*)',
  caseSensitive: false,
);

String prepareMsg(MsgContent? content) {
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

String parseEditMsg(types.Message message) {
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
      }

      // Parse data
      final messageDocument = parse(msg);
      return messageDocument.body?.text ?? '';
    }
  }
  return '';
}

Future<void> parseUserMentionText(
  String htmlText,
  String roomId,
  ActerTriggerAutoCompleteTextController controller,
  WidgetRef ref,
) async {
  final roomMentions = await ref.read(membersIdsProvider(roomId).future);
  final inputNotifier = ref.read(chatInputProvider.notifier);
  // Regular expression to match mention links
  final mentionRegex = RegExp(r'\[@([^\]]+)\]\(https://matrix\.to/#/([^)]+)\)');
  List<TaggedText> tags = [];
  String parsedText = htmlText;
  // Find all matches
  final matches = mentionRegex.allMatches(htmlText);

  int offset = 0;
  for (final match in matches) {
    final linkedName = match.group(1);
    final userId = match.group(2);

    String? displayName;
    bool isValidMention = false;

    if (linkedName != null && userId != null) {
      displayName = linkedName;
      isValidMention = roomMentions.any((uId) => uId == userId);
    }
    if (isValidMention && userId != null && displayName != null) {
      final simpleMention = '@$displayName';
      final startIndex = match.start - offset;
      final endIndex = startIndex + simpleMention.length;
      // restore mention state of input
      inputNotifier.addMention(displayName, userId);
      // restore tags
      tags.add(
        TaggedText(
          trigger: '@',
          displayText: simpleMention,
          start: startIndex,
          end: endIndex,
        ),
      );

      // Replace the mention in parsed text
      parsedText = parsedText.replaceRange(
        startIndex,
        match.end - offset,
        simpleMention,
      );
      offset += (match.end - match.start) - simpleMention.length;
    }
  }

  // Set the parsed text to the text controller
  controller.text = parsedText;

  // Apply the tags to the text controller
  for (final tag in tags) {
    controller.addTag(tag);
  }
}

// save composer draft object handler
Future<void> saveDraft(
  String text,
  String? htmlText,
  String roomId,
  WidgetRef ref,
) async {
  // get the convo object to initiate draft
  final chat = await ref.read(chatProvider(roomId).future);
  final messageId = ref.read(chatInputProvider).selectedMessage?.id;
  final mentions = ref.read(chatInputProvider).mentions;
  final userMentions = [];
  if (mentions.isNotEmpty) {
    mentions.forEach((key, value) {
      userMentions.add(value);
      htmlText = htmlText?.replaceAll(
        '@$key',
        '[@$key](https://matrix.to/#/$value)',
      );
    });
  }

  if (chat != null) {
    if (messageId != null) {
      final selectedMessageState =
          ref.read(chatInputProvider).selectedMessageState;
      if (selectedMessageState == SelectedMessageState.edit) {
        await chat.saveMsgDraft(text, htmlText, 'edit', messageId);
      } else if (selectedMessageState == SelectedMessageState.replyTo) {
        await chat.saveMsgDraft(text, htmlText, 'reply', messageId);
      }
    } else {
      await chat.saveMsgDraft(text, htmlText, 'new', null);
    }
  }
}

Future<void> onMessageLinkTap(
  Uri uri,
  WidgetRef ref,
  BuildContext context,
) async {
  try {
    await handleDeepLinkUri(
      context: context,
      ref: ref,
      uri: uri,
      throwNoError: true,
    );
  } on UriParseError {
    if (!context.mounted) {
      return;
    }
    final roomId = getRoomIdFromLink(uri);

    ///If link is type of matrix room link
    if (roomId != null) {
      goToChat(context, roomId);
    }

    ///If link is other than matrix room link
    ///Then open it on browser
    else {
      await openLink(uri.toString(), context);
    }
  }
}
