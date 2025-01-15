import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  void _initializeTabs() {
    final total = widget.reactions.fold<int>(
      0,
      (sum, reaction) => sum + reaction.$2.length,
    );

    _tabs = [
      Tab(child: Chip(label: Text('All $total'))),
      ...widget.reactions.map(
        (reaction) => Tab(
          child: Chip(
            avatar: Text(reaction.$1, style: EmojiConfig.emojiTextStyle),
            label: Text('${reaction.$2.length}'),
          ),
        ),
      ),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabBar(),
        _buildTabBarView(),
      ],
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
    final reactionData = _processReactionData();

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TabBarView(
          controller: _tabController,
          children: [
            _ReactionUsersList(
              roomId: widget.roomId,
              users: reactionData.allUsers,
              userReactions: reactionData.userReactions,
            ),
            ...widget.reactions.map(
              (reaction) => _ReactionUsersList(
                roomId: widget.roomId,
                users: reactionData.reactionUsers[reaction.$1] ?? [],
                userReactions: reactionData.userReactions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({
    List<String> allUsers,
    Map<String, List<String>> userReactions,
    Map<String, List<String>> reactionUsers,
  }) _processReactionData() {
    final userReactions = <String, List<String>>{};
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

    final allUsers = userReactions.keys.toList()
      ..sort(
        (a, b) => (userReactions[b]?.length ?? 0)
            .compareTo(userReactions[a]?.length ?? 0),
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

class ReactionUserItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(userId),
      trailing: Wrap(
        children: emojis
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