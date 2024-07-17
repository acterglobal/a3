import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:multi_trigger_autocomplete/multi_trigger_autocomplete.dart';

class MentionProfileBuilder extends ConsumerWidget {
  final BuildContext ctx;
  final RoomQuery roomQuery;

  const MentionProfileBuilder({
    super.key,
    required this.ctx,
    required this.roomQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var memberIds = ref.watch(membersIdsProvider((roomQuery.roomId)));
    if (memberIds.valueOrNull != null) {
      final data = memberIds.requireValue;
      final users = data.fold<Map<String, AvatarInfo>>({}, (map, uId) {
        // keeps avatar data updated with mention list
        final profile = ref.watch(
          memberAvatarInfoProvider(
            (roomId: roomQuery.roomId, userId: uId),
          ),
        );

        final normalizedId = uId.toLowerCase();
        final normalizedName = profile.displayName?.toLowerCase() ?? '';
        final normalizedQuery = roomQuery.query.toLowerCase();

        if (normalizedId.contains(normalizedQuery) ||
            normalizedName.contains(normalizedQuery)) {
          map[uId] = profile;
        }

        return map;
      });
      final userIds = users.keys.toList();
      if (users.isEmpty) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(L10n.of(context).noUserFoundTitle),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Card(
              margin: const EdgeInsets.all(8),
              elevation: 2,
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final userId = userIds.elementAt(index);
                  final user = users[userId]!;
                  return ListTile(
                    onTap: () {
                      final autocomplete = MultiTriggerAutocomplete.of(ctx);
                      ref
                          .read(chatInputProvider(roomQuery.roomId).notifier)
                          .addMention(user.displayName ?? '', user.uniqueId);
                      return autocomplete.acceptAutocompleteOption(
                        user.displayName ?? user.uniqueId.substring(1),
                      );
                    },
                    leading: ActerAvatar(
                      options: AvatarOptions.DM(
                        user,
                        size: 18,
                      ),
                    ),
                    title: Text(user.displayName ?? user.uniqueId),
                    titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                    subtitleTextStyle: Theme.of(context).textTheme.labelMedium,
                    subtitle:
                        user.displayName != null ? Text(user.uniqueId) : null,
                  );
                },
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
