import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ReactionData =
    ({
      List<String> allUsers,
      Map<String, List<String>> userReactions,
      Map<String, List<String>> reactionUsers,
    });

class ReactionDetailsSheet extends ConsumerStatefulWidget {
  final String roomId;
  final List<ReactionItem> reactions;

  const ReactionDetailsSheet({
    super.key,
    required this.roomId,
    required this.reactions,
  });

  @override
  ConsumerState<ReactionDetailsSheet> createState() =>
      _ReactionDetailsSheetState();
}

class _ReactionDetailsSheetState extends ConsumerState<ReactionDetailsSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<Tab> _tabs;
  late final ReactionData _reactionData;

  @override
  void initState() {
    super.initState();
    _reactionData = _processReactionData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTabs();
  }

  @override
  void didUpdateWidget(ReactionDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if reactions have changed
    final hasChanged =
        widget.reactions.length != oldWidget.reactions.length ||
        widget.reactions.any((reaction) {
          final oldReaction = oldWidget.reactions.firstWhere(
            (old) => old.$1 == reaction.$1,
            orElse: () => (reaction.$1, []),
          );
          return reaction.$2.length != oldReaction.$2.length;
        });

    if (hasChanged) {
      setState(() {
        _reactionData = _processReactionData();
        // dispose old one
        _tabController.dispose();
        _initializeTabs();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTabs() {
    final total = widget.reactions.fold<int>(
      0,
      (sum, reaction) => sum + reaction.$2.length,
    );

    _tabs = [
      Tab(child: Text(L10n.of(context).allReactionsCount(total))),
      ...widget.reactions.map(
        (reaction) => Tab(
          key: Key('reaction-tab-${reaction.$1}'),
          child: Row(
            children: [
              Text(reaction.$1, style: EmojiConfig.emojiTextStyle),
              const SizedBox(width: 6),
              Text(reaction.$2.length.toString()),
            ],
          ),
        ),
      ),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildTabBar(), _buildTabBarView()],
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return TabBar(
      isScrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      controller: _tabController,
      indicator: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      tabs: _tabs,
    );
  }

  Widget _buildTabBarView() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TabBarView(
          controller: _tabController,
          children: [
            _ReactionUsersList(
              roomId: widget.roomId,
              users: _reactionData.allUsers,
              userReactions: _reactionData.userReactions,
            ),
            ...widget.reactions.map(
              (reaction) => _ReactionUsersList(
                roomId: widget.roomId,
                users: _reactionData.reactionUsers[reaction.$1] ?? [],
                userReactions: _reactionData.userReactions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ReactionData _processReactionData() {
    // how many reactions per user
    final userReactions = <String, List<String>>{};
    // how many users of single reaction
    final reactionUsers = <String, List<String>>{};

    for (final reaction in widget.reactions) {
      final emoji = reaction.$1;
      reactionUsers[emoji] = [];

      for (final record in reaction.$2) {
        final userId = record.senderId().toString();
        userReactions.putIfAbsent(userId, () => []).add(emoji);
        reactionUsers[emoji]?.add(userId);
      }
    }

    final allUsers =
        userReactions.keys.toList()..sort(
          (a, b) => (userReactions[b]?.length ?? 0).compareTo(
            userReactions[a]?.length ?? 0,
          ),
        );

    return (
      allUsers: allUsers,
      userReactions: userReactions,
      reactionUsers: reactionUsers,
    );
  }
}

// Users list in reaction details
class _ReactionUsersList extends StatelessWidget {
  final String roomId;
  final List<String> users;
  final Map<String, List<String>> userReactions;

  const _ReactionUsersList({
    required this.roomId,
    required this.users,
    required this.userReactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userId = users[index];
        return ReactionUserItem(
          roomId: roomId,
          userId: userId,
          emojis: userReactions[userId] ?? [],
        );
      },
      separatorBuilder:
          (context, index) => Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            indent: 50,
            endIndent: 0,
          ),
    );
  }
}

class ReactionUserItem extends ConsumerWidget {
  final String roomId;
  final String userId;
  final List<String> emojis;

  const ReactionUserItem({
    super.key,
    required this.roomId,
    required this.userId,
    required this.emojis,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ActerAvatar(
        options: AvatarOptions.DM(
          AvatarInfo(
            uniqueId: userId,
            displayName: memberInfo.displayName,
            avatar: memberInfo.avatar,
          ),
          size: 18,
        ),
      ),
      title: Text(
        memberInfo.displayName ?? userId,
        style: theme.textTheme.labelLarge,
      ),
      subtitle:
          memberInfo.displayName != null
              ? Text(userId, style: theme.textTheme.labelMedium)
              : null,
      trailing: Wrap(
        children:
            emojis
                .map(
                  (emoji) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(emoji, style: EmojiConfig.emojiTextStyle),
                  ),
                )
                .toList(),
      ),
    );
  }
}
