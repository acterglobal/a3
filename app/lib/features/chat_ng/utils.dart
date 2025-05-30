import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> saveMsgDraft(
  String text,
  String? htmlText,
  String roomId,
  WidgetRef ref,
) async {
  // get the convo object to initiate draft
  final chat = await ref.read(chatProvider(roomId).future);
  final chatEditorState = ref.read(chatEditorStateProvider);
  final messageId = chatEditorState.selectedMsgItem?.eventId();

  if (chat != null && messageId != null) {
    if (chatEditorState.isEditing) {
      await chat.saveMsgDraft(text, htmlText, 'edit', messageId);
    } else if (chatEditorState.isReplying) {
      await chat.saveMsgDraft(text, htmlText, 'reply', messageId);
    } else {
      await chat.saveMsgDraft(text, htmlText, 'new', null);
    }
  }
}

// whether event is state event
bool isStateEvent(String eventType) {
  return [
    'm.policy.rule.room',
    'm.policy.rule.server',
    'm.policy.rule.user',
    'm.room.aliases',
    'm.room.avatar',
    'm.room.canonical_alias',
    'm.room.create',
    'm.room.encryption',
    'm.room.guest_access',
    'm.room.history_visibility',
    'm.room.join_rules',
    'm.room.name',
    'm.room.pinned_events',
    'm.room.power_levels',
    'm.room.server_acl',
    'm.room.third_party_invite',
    'm.room.tombstone',
    'm.room.topic',
    'm.space.child',
    'm.space.parent',
  ].contains(eventType);
}

bool isMemberEvent(String eventType) =>
    ['MembershipChange', 'ProfileChange'].contains(eventType);

/// The Material Design accent color swatches.
const List<MaterialAccentColor> chatBubbleDisplayNameColors =
    <MaterialAccentColor>[
      Colors.redAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.lightBlueAccent,
      Colors.cyanAccent,
      Colors.tealAccent,
      Colors.greenAccent,
      Colors.lightGreenAccent,
      Colors.limeAccent,
      Colors.yellowAccent,
      Colors.amberAccent,
      Colors.orangeAccent,
      Colors.deepOrangeAccent,
    ];

// inspired by https://github.com/mathiasbynens/emoji-regex under MIT license
final _emojiRegex = RegExp(
  r'^(\p{RI}{2}|(?![#*\d](?!\uFE0F?\u20E3))\p{Emoji}(?:\p{EMod}|[\u{E0020}-\u{E007E}]+\u{E007F}|\uFE0F?\u20E3?)(?:\u200D\p{Emoji}(?:\p{EMod}|[\u{E0020}-\u{E007E}]+\u{E007F}|\uFE0F?\u20E3?))*|\s)+$',
  unicode: true,
  multiLine: true,
);

bool isOnlyEmojis(String text) {
  return _emojiRegex.hasMatch(text.trim());
}

extension ColorAsCssString on Color {
  String toCssString() =>
      'rgba(${(255 * r).toInt()},${(255 * g).toInt()},${(255 * b).toInt()},${a.toStringAsFixed(2)})';
}
