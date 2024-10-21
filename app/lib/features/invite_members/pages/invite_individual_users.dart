import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:acter/features/member/widgets/user_search_results.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteIndividualUsers extends ConsumerWidget {
  final String roomId;

  const InviteIndividualUsers({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(L10n.of(context).inviteIndividualUsersTitle),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              lang.inviteIndividualUsersDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ActerSearchWidget(
              initialText: ref.read(userSearchValueProvider),
              hintText: lang.searchUsernameToStartDM,
              onChanged: (value) {
                final notifier = ref.read(userSearchValueProvider.notifier);
                notifier.update((state) => value);
              },
              onClear: () {
                final notifier = ref.read(userSearchValueProvider.notifier);
                notifier.state = null;
              },
            ),
            const SizedBox(height: 10),
            _buildUserDirectInvite(ref),
            Expanded(
              child: UserSearchResults(
                roomId: roomId,
                userItemBuilder: ({
                  required bool isSuggestion,
                  required UserProfile profile,
                }) {
                  return UserBuilder(
                    userId: profile.userId().toString(),
                    roomId: roomId,
                    userProfile: profile,
                    includeSharedRooms: isSuggestion,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDirectInvite(WidgetRef ref) {
    final searchValue = ref.watch(userSearchValueProvider);
    if (searchValue != null && searchValue.isNotEmpty == true) {
      final cleaned = searchValue.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            if (userNameRegExp.hasMatch(cleaned))
              DirectInvite(
                roomId: roomId,
                userId: cleaned,
              ),
            if (noAtUserNameRegExp.hasMatch(cleaned))
              DirectInvite(
                roomId: roomId,
                userId: '@$cleaned',
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
