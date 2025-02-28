import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
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
      Tab(child: Chip(label: Text(L10n.of(context).allReactionsCount(total)))),
      ...widget.reactions.map(
        (reaction) => Tab(
          key: Key('reaction-tab-${reaction.$1}'),
          child: Chip(
            avatar: Text(reaction.$1, style: EmojiConfig.emojiTextStyle),
            label: Text(reaction.$2.length.toString()),
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
    return TabBar(
      isScrollable: true,
      padding: const EdgeInsets.all(24),
      controller: _tabController,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      indicator: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userId = users[index];
        return ReactionUserItem(
          roomId: roomId,
          userId: userId,
          emojis: userReactions[userId] ?? [],
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
      leading: ActerAvatar(
        options: AvatarOptions.DM(
          AvatarInfo(
            uniqueId: userId,
            displayName: memberInfo.displayName,
            avatar: memberInfo.avatar,
          ),
        ),
      ),
      title: Text(memberInfo.displayName ?? userId),
      subtitle:
          memberInfo.displayName != null
              ? Text(userId, style: theme.textTheme.labelLarge)
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
