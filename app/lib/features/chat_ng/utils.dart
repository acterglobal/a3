import 'dart:math';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
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
  /// Base height for the editor (single line)
  static const double baseHeight = 56.0;

  /// Height per additional line
  static const double lineHeight = 20.0;

  /// Maximum allowed height for the editor
  static const double maxHeight = 200.0;

  /// Height threshold for enabling auto-scrolling
  static const double scrollThreshold = 96.0;

  /// Returns the appropriate height for the editor based on line count
  static double calculateContentHeight(String text) {
    final lineCount = text.split('\n').length - 1;

    if (lineCount <= 0) {
      return baseHeight;
    }

    double height = baseHeight;
    height += lineCount * lineHeight;

    return min(height, maxHeight);
  }

  static bool shouldEnableScrolling(double contentHeight) {
    return contentHeight > scrollThreshold;
  }
}
