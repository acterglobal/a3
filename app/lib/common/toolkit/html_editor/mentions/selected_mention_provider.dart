import 'package:acter/common/toolkit/html_editor/mentions/models/mention_type.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mentionQueryProvider = StateProvider<String?>((ref) => null);

final filteredUserSuggestionsProvider =
    Provider.family<Map<String, String>, String>((ref, roomId) {
      final suggestions = ref.watch(userMentionSuggestionsProvider(roomId));
      if (suggestions == null) return {};
      final query = ref.watch(mentionQueryProvider);
      if (query == null) return suggestions;
      return Map.fromEntries(
        suggestions.entries.where((entry) {
          final displayName = entry.value.toLowerCase();
          final id = entry.key.toLowerCase();
          return displayName.contains(query) || id.contains(query);
        }),
      );
    });

final filteredRoomSuggestionsProvider =
    Provider.family<Map<String, String>, String>((ref, roomId) {
      final suggestions = ref.watch(roomMentionsSuggestionsProvider(roomId));
      if (suggestions == null) return {};
      final query = ref.watch(mentionQueryProvider);
      if (query == null) return suggestions;
      return Map.fromEntries(
        suggestions.entries.where((entry) {
          final displayName = entry.value.toLowerCase();
          final id = entry.key.toLowerCase();
          return displayName.contains(query) || id.contains(query);
        }),
      );
    });

final selecteUserMentionProvider =
    NotifierProvider.family<SelectedMentionNotifier, int?, String>(
      () => SelectedMentionNotifier(MentionType.user),
    );

final selectedRoomMentionProvider =
    NotifierProvider.family<SelectedMentionNotifier, int?, String>(
      () => SelectedMentionNotifier(MentionType.room),
    );

class SelectedMentionNotifier extends FamilyNotifier<int?, String> {
  late String _roomId;
  late MentionType _mentionType;

  SelectedMentionNotifier(this._mentionType);

  @override
  int? build(String roomId) {
    _roomId = roomId;
    return null;
  }

  int? get maxCount => switch (_mentionType) {
    MentionType.user =>
      ref.watch(filteredUserSuggestionsProvider(_roomId)).length,
    MentionType.room =>
      ref.watch(filteredRoomSuggestionsProvider(_roomId)).length,
  };

  void _updateIndex(int newIndex) {
    final filtered = maxCount;
    int? updateIndex;
    if (filtered != null) {
      if (newIndex < 0) {
        updateIndex = 0;
      } else if (newIndex >= filtered) {
        updateIndex = filtered - 1;
      }
    }
    state = updateIndex;
  }

  // external control functions
  void next() {
    final selected = state;
    if (selected == null) _updateIndex(0);
    _updateIndex(selected! + 1);
  }

  void prev() {
    final selected = state;
    if (selected == null) _updateIndex(0);
    _updateIndex(selected! - 1);
  }
}
