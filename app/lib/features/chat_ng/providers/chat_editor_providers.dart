import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:acter/features/chat_ng/models/chat_editor_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_editor_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// global key  for determining build context of the editor
final chatEditorKeyProvider = Provider.family<GlobalKey, String>(
  (ref, roomId) => GlobalKey(debugLabel: 'chat-editor-key-$roomId'),
);

final chatEditorStateProvider =
    NotifierProvider.autoDispose<ChatEditorNotifier, ChatEditorState>(
      () => ChatEditorNotifier(),
    );

/// High Level Provider to fetch user/room mentions
final mentionSuggestionsProvider =
    StateProvider.family<Map<String, String>?, (String, MentionType)>((
      ref,
      params,
    ) {
      final (roomId, mentionType) = params;
      return switch (mentionType) {
        MentionType.user => ref.watch(userMentionSuggestionsProvider(roomId)),
        MentionType.room => ref.watch(roomMentionsSuggestionsProvider(roomId)),
      };
    });

/// Provider to fetch user mentions
final userMentionSuggestionsProvider =
    StateProvider.family<Map<String, String>?, String>((ref, roomId) {
      final userId = ref.watch(myUserIdStrProvider);
      final members = ref.watch(membersIdsProvider(roomId)).valueOrNull;
      if (members == null) {
        return {};
      }
      return members.fold<Map<String, String>>({}, (map, uId) {
        if (uId != userId) {
          final displayName = ref.watch(
            memberDisplayNameProvider((roomId: roomId, userId: uId)),
          );
          map[uId] = displayName.valueOrNull ?? '';
        }
        return map;
      });
    });

/// Provider to fetch room mentions
final roomMentionsSuggestionsProvider =
    StateProvider.family<Map<String, String>?, String>((ref, roomId) {
      final rooms = ref.watch(chatIdsProvider);
      return rooms.fold<Map<String, String>>({}, (map, roomId) {
        if (roomId == roomId) return map;

        final displayName = ref.watch(roomDisplayNameProvider(roomId));
        map[roomId] = displayName.valueOrNull ?? '';
        return map;
      });
    });
