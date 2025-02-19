import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef UserItemBuilder = Widget Function({
  required UserProfile profile,
  required bool isSuggestion,
});

class UserSearchResults extends ConsumerWidget {
  final UserItemBuilder userItemBuilder;
  final String? roomId;
  const UserSearchResults({
    super.key,
    required this.userItemBuilder,
    this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final suggestedUsers =
        ref.watch(filteredSuggestedUsersProvider(roomId)).valueOrNull ?? [];
    final foundUsers = ref.watch(searchResultProvider).valueOrNull ?? [];

    if (suggestedUsers.isEmpty && foundUsers.isEmpty) {
      // nothing found
      return Center(
        child: EmptyState(
          title: lang.noUserFoundTitle,
          subtitle: lang.noUserFoundSubtitle,
          image: 'assets/images/empty_activity.svg',
        ),
      );
    }

    return ListView.builder(
      itemBuilder: (context, position) {
        late UserProfile user;
        bool showRooms = false;
        if (position >= suggestedUsers.length) {
          user = foundUsers[position - suggestedUsers.length];
        } else {
          user = suggestedUsers[position];
          showRooms = true;
        }

        final userWidget = userItemBuilder(
          isSuggestion: showRooms,
          profile: user,
        );
        if (position == 0 && suggestedUsers.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  lang.suggestedUsers,
                  style: textTheme.titleSmall,
                ),
              ),
              userWidget,
            ],
          );
        }
        if (position == suggestedUsers.length && foundUsers.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  lang.usersfoundDirectory,
                  style: textTheme.titleSmall,
                ),
              ),
              userWidget,
            ],
          );
        }
        return userWidget;
      },
      itemCount: suggestedUsers.length + foundUsers.length,
    );
  }
}
