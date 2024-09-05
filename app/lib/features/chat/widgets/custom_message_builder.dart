import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/location_message.dart';
import 'package:acter/features/chat/widgets/messages/membership_update.dart';
import 'package:acter/features/chat/widgets/messages/poll_start_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat/widgets/messages/simple_state_update.dart';
import 'package:acter/features/chat/widgets/messages/sticker_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::custom_message_builder');

class CustomMessageBuilder extends StatelessWidget {
  final types.CustomMessage message;
  final int messageWidth;

  const CustomMessageBuilder({
    super.key,
    required this.message,
    required this.messageWidth,
  });

  @override
  Widget build(BuildContext context) {
    // state event
    switch (message.metadata?['eventType']) {
      case 'm.room.encrypted':
        return const EncryptedMessageWidget();
      case 'm.room.member':
        return MembershipUpdateWidget(message: message);
      case 'm.room.message':
        if (message.metadata?['msgType'] == 'm.location') {
          return LocationMessageWidget(message: message);
        }
        _log.warning(
          'Asked to render room message that isn’t a location isn’t supported. $message',
        );
        return const SizedBox.shrink();
      case 'm.room.redaction':
        return const RedactedMessageWidget();
      case 'm.sticker':
        return StickerMessageWidget(
          message: message,
          messageWidth: messageWidth,
        );
      case 'm.poll.start':
        return PollStartMessageWidget(message: message);
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
        return SimpleStateUpdateWidget(message: message);
    }

    _log.warning('Asked to render an unsupported custom message $message');
    return const SizedBox();
  }
}
