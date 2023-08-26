import 'dart:convert';

import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class CustomMessageBuilder extends StatelessWidget {
  final types.CustomMessage message;
  final int messageWidth;

  const CustomMessageBuilder({
    Key? key,
    required this.message,
    required this.messageWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // state event
    switch (message.metadata?['eventType']) {
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical.alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history.visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned.events':
      case 'm.room.power.levels':
      case 'm.room.server.acl':
      case 'm.room.third.party.invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
      case 'm.room.member':
        String? text = message.metadata?['body'];
        return text == null
            ? const SizedBox.shrink()
            : Container(
                padding: const EdgeInsets.only(left: 10, bottom: 5),
                child: RichText(
                  text: TextSpan(
                    text: message.author.id,
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      const WidgetSpan(child: SizedBox(width: 3)),
                      TextSpan(
                        text: text,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              );
    }

    // message event
    switch (message.metadata?['eventType']) {
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
      case 'm.key.verification.accept':
      case 'm.key.verification.cancel':
      case 'm.key.verification.done':
      case 'm.key.verification.key':
      case 'm.key.verification.mac':
      case 'm.key.verification.ready':
      case 'm.key.verification.start':
        break;
      case 'm.room.encrypted':
        String text =
            '***Failed to decrypt message. Re-request session keys.***';
        return Container(
          padding: const EdgeInsets.all(18),
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).colorScheme.neutral5),
          ),
        );
      case 'm.room.redaction':
        String text = '***This message has been deleted.***';
        return Container(
          padding: const EdgeInsets.all(18),
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).colorScheme.neutral5),
          ),
        );
      case 'm.sticker':
        return Container(
          width: message.metadata?['width'],
          padding: const EdgeInsets.all(18),
          constraints: const BoxConstraints(minWidth: 57),
          child: Image.memory(
            base64Decode(message.metadata?['base64']),
            errorBuilder: (
              BuildContext context,
              Object url,
              StackTrace? error,
            ) {
              return Text('Could not load image due to $error');
            },
            frameBuilder: (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: frame != null
                    ? child
                    : const SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(strokeWidth: 6),
                      ),
              );
            },
            cacheWidth: 256,
            width: messageWidth.toDouble() / 2,
            fit: BoxFit.cover,
          ),
        );
    }

    return const SizedBox();
  }
}
