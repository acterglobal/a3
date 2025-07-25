import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/html_editor/mentions/widgets/mention_item.dart';
import 'package:acter/common/toolkit/html_editor/mentions/models/mention_type.dart';
import 'package:acter/common/toolkit/html_editor/mentions/selected_mention_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserMentionList extends ConsumerWidget {
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final String roomId;
  final MentionSelectedFn onSelected;

  const UserMentionList({
    super.key,
    required this.onDismiss,
    required this.onShow,
    required this.roomId,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => MentionList(
    roomId: roomId,
    onDismiss: onDismiss,
    onShow: onShow,
    // the actual provider
    mentionsProvider: filteredUserSuggestionsProvider(roomId),
    selectedIndexProvider: selecteUserMentionProvider(roomId),
    avatarBuilder: (matchId, ref) {
      final avatarInfo = ref.watch(
        memberAvatarInfoProvider((roomId: roomId, userId: matchId)),
      );
      return AvatarOptions.DM(avatarInfo, size: 18);
    },
    // the fields
    headerTitle: L10n.of(context).users,
    notFoundTitle: L10n.of(context).noUserFoundTitle,
    onSelected: (id, displayName) =>
        onSelected(MentionType.user, id, displayName),
  );
}

class RoomMentionList extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final String roomId;
  final MentionSelectedFn onSelected;
  const RoomMentionList({
    super.key,
    required this.onDismiss,
    required this.onShow,
    required this.roomId,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => MentionList(
    roomId: roomId,
    onDismiss: onDismiss,
    onShow: onShow,
    // the actual provider
    mentionsProvider: filteredRoomSuggestionsProvider(roomId),
    avatarBuilder: (matchId, ref) {
      final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
      return AvatarOptions(avatarInfo, size: 28);
    },
    // the fields
    headerTitle: L10n.of(context).chats,
    notFoundTitle: L10n.of(context).noChatsFound,
    selectedIndexProvider: selectedRoomMentionProvider(roomId),
    onSelected: (id, displayName) =>
        onSelected(MentionType.room, id, displayName),
  );
}

class MentionList extends ConsumerStatefulWidget {
  const MentionList({
    super.key,
    required this.roomId,
    required this.mentionsProvider,
    required this.avatarBuilder,
    required this.headerTitle,
    required this.notFoundTitle,
    required this.onDismiss,
    required this.onShow,
    required this.onSelected,
    required this.selectedIndexProvider,
  });

  final String roomId;
  final ProviderBase<Map<String, String>?> mentionsProvider;
  final AvatarOptions Function(String matchId, WidgetRef ref) avatarBuilder;
  final String headerTitle;
  final String notFoundTitle;
  final VoidCallback onDismiss;
  final VoidCallback onShow;
  final ProviderBase<int?> selectedIndexProvider;
  final Function(String id, String? displayName) onSelected;
  @override
  ConsumerState<MentionList> createState() => MentionHandlerState();
}

class MentionHandlerState extends ConsumerState<MentionList> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    widget.onDismiss();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, String> get filteredSuggestions =>
      ref.watch(widget.mentionsProvider) ?? {};

  @override
  Widget build(BuildContext context) {
    if (filteredSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Text(widget.headerTitle),
        ),
        _buildMenuList(),
      ],
    );
  }

  Widget _buildMenuList() {
    final theme = Theme.of(context);
    final options = widget.avatarBuilder;

    return Flexible(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        controller: _scrollController,
        itemCount: filteredSuggestions.length,
        separatorBuilder: (context, index) =>
            Divider(indent: 70, color: theme.unselectedWidgetColor, height: 1),
        itemBuilder: (context, index) {
          final mentionId = filteredSuggestions.keys.elementAt(index);
          final displayName = filteredSuggestions.values.elementAt(index);

          return MentionItem(
            mentionId: mentionId,
            displayName: displayName,
            avatarOptions: options(mentionId, ref),
            selected: index == ref.watch(widget.selectedIndexProvider),
            onTap: (String id, {String? displayName}) =>
                widget.onSelected(id, displayName),
          );
        },
      ),
    );
  }
}
