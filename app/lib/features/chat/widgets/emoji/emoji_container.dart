import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/widgets/emoji/emoji_reaction_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EmojiContainer extends StatefulWidget {
  final String roomId;
  final Function(String messageId, String emoji) onToggle;
  final bool isAuthor;
  final types.Message message;
  final bool nextMessageInGroup;

  const EmojiContainer({
    super.key,
    required this.roomId,
    required this.onToggle,
    required this.isAuthor,
    required this.message,
    required this.nextMessageInGroup,
  });

  @override
  State<StatefulWidget> createState() => _EmojiContainerState();
}

class _EmojiContainerState extends State<EmojiContainer>
    with TickerProviderStateMixin {
  late TabController tabBarController;
  List<Tab> reactionTabs = [];

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(
      length: reactionTabs.length,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? reactions = widget.message.metadata?['reactions'];
    if (reactions == null) return const SizedBox();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      color: Theme.of(context).colorScheme.surface,
      child: Wrap(
        direction: Axis.horizontal,
        runSpacing: 3,
        children: reactions.entries.map((entry) {
          final records = entry.value as List<ReactionRecord>;
          final sentByMe = records.any((x) => x.sentByMe());
          final emoji = Text(
            entry.key,
            style: EmojiConfig.emojiTextStyle,
          );
          final moreThanOne = records.length > 1;
          return InkWell(
            onLongPress: () {
              showEmojiReactionsSheet(reactions, widget.roomId);
            },
            onTap: () {
              widget.onToggle(widget.message.id, entry.key);
            },
            child: Chip(
              padding: moreThanOne
                  ? const EdgeInsets.only(right: 4)
                  : const EdgeInsets.symmetric(horizontal: 2),
              backgroundColor: sentByMe
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surface,
              visualDensity: VisualDensity.compact,
              labelPadding: const EdgeInsets.all(0),
              shape: const StadiumBorder(
                side: BorderSide(
                  color: Colors.transparent,
                ),
              ),
              avatar: moreThanOne ? emoji : null,
              label: moreThanOne
                  ? Text(
                      records.length.toString(),
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  : emoji,
            ),
          );
        }).toList(),
      ),
    );
  }

  //Emoji reaction info bottom sheet.
  void showEmojiReactionsSheet(Map<String, dynamic> reactions, String roomId) {
    Map<String, List<String>> reactionsByUser = {};
    Map<String, List<String>> usersByReaction = {};
    reactions.forEach((key, value) {
      final records = value as List<ReactionRecord>;
      for (final reaction in records) {
        final userId = reaction.senderId().toString();
        usersByReaction.update(
          key,
          (v) => v.contains(userId) ? v : [...v, userId],
          ifAbsent: () => [userId],
        );
        reactionsByUser.update(
          userId,
          (v) => v.contains(key) ? v : [...v, key],
          ifAbsent: () => [key],
        );
      }
    });
    // sort the users per item on the number of emojis sent - highest first
    usersByReaction.forEach((key, users) {
      users.sort((user1, user2) {
        final user1Reactions = reactionsByUser[user1];
        if (user1Reactions == null) throw 'user1 reactions not available';
        final user2Reactions = reactionsByUser[user2];
        if (user2Reactions == null) throw 'user2 reactions not available';
        return user2Reactions.length.compareTo(user1Reactions.length);
      });
    });
    final allUsers = reactionsByUser.keys.toList();
    allUsers.sort((user1, user2) {
      final user1Reactions = reactionsByUser[user1];
      if (user1Reactions == null) throw 'user1 reactions not available';
      final user2Reactions = reactionsByUser[user2];
      if (user2Reactions == null) throw 'user2 reactions not available';
      return user2Reactions.length.compareTo(user1Reactions.length);
    });

    num total = 0;
    if (mounted) {
      setState(() {
        reactions.forEach((key, value) {
          total += value.length;
          reactionTabs.add(
            Tab(
              child: Chip(
                avatar: Text(key, style: EmojiConfig.emojiTextStyle),
                label: Text('${value.length}'),
              ),
            ),
          );
        });
        reactionTabs.insert(
          0,
          Tab(
            child: Chip(
              label: Text('${L10n.of(context).all} $total'),
            ),
          ),
        );
        tabBarController = TabController(
          length: reactionTabs.length,
          vsync: this,
        );
      });
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15),
        ),
      ),
      isDismissible: true,
      builder: (BuildContext context) {
        final tabs = [
          _ReactionListing(
            roomId: roomId,
            users: allUsers,
            usersMap: reactionsByUser,
          ),
        ];
        for (final key in reactions.keys.toList()) {
          final users = usersByReaction[key];
          if (users == null) throw 'Users for reaction not found';
          tabs.add(
            _ReactionListing(
              roomId: roomId,
              users: users,
              usersMap: reactionsByUser,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TabBar(
                isScrollable: true,
                padding: const EdgeInsets.all(24),
                controller: tabBarController,
                overlayColor:
                    WidgetStateProperty.all<Color>(Colors.transparent),
                indicator: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                dividerColor: Colors.transparent,
                tabs: reactionTabs,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TabBarView(
                  viewportFraction: 1.0,
                  controller: tabBarController,
                  children: tabs,
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() => reactionTabs.clear());
      }
    });
  }
}

class _ReactionListing extends StatelessWidget {
  final String roomId;
  final List<String> users;
  final Map<String, List<String>> usersMap; // UserId -> List of Emoji

  const _ReactionListing({
    required this.roomId,
    required this.users,
    required this.usersMap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        final userId = users[index];
        final emojis = usersMap[userId];
        if (emojis == null) throw 'emoji list of user not available';
        return EmojiReactionItem(
          roomId: roomId,
          userId: userId,
          emojis: emojis,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
    );
  }
}
