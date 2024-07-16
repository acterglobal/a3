import 'package:acter/common/models/types.dart';
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
    final mentions = ref.watch(chatMentionsProvider((roomQuery.roomId)));

    if (mentions.valueOrNull != null) {
      final data = mentions.requireValue;
      final users = data.where((u) {
        final normalizedId = u.uniqueId.toLowerCase();
        final normalizedName = u.displayName?.toLowerCase() ?? '';
        final normalizedQuery = roomQuery.query.toLowerCase();
        return normalizedId.contains(normalizedQuery) ||
            normalizedName.contains(normalizedQuery);
      });

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
          Card(
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
                final user = users.elementAt(index);
                return ListTile(
                  onTap: () {
                    final autocomplete = MultiTriggerAutocomplete.of(ctx);
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
                  title: Text(user.displayName ?? data[index].uniqueId),
                  titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                  subtitleTextStyle: Theme.of(context).textTheme.labelMedium,
                  subtitle:
                      user.displayName != null ? Text(user.uniqueId) : null,
                );
              },
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
