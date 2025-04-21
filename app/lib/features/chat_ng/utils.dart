import 'dart:math';

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

class ChatEditorUtils {
  /// base height for the editor (single line)
  static const double baseHeight = 56.0;

  /// toolbar offset for the editor
  static const double toolbarOffset = 50.0;

  /// max height for the editor
  static const double maxHeight = 200.0;

  static const double defaultAutoScrollEdgeOffset = 15.0;

  /// get responsive auto-scroll edge offset based on screen size
  /// this helps ensure the auto-scroll behavior works well on different screen sizes
  /// by adjusting the edge offset based on the available height.
  static double getAutoScrollEdgeOffset(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // For very small screens
    if (screenHeight < 600) {
      return 10.0;
    }

    // For medium screens
    if (screenHeight < 1000) {
      return max(15.0, toolbarOffset * 0.3);
    }

    // For large screens
    return max(20.0, toolbarOffset * 0.4);
  }
}
