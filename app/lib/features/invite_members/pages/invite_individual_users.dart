import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/user_builder.dart';
import 'package:acter/features/invite_members/providers/invite_providers.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::invite::individual_users');

class InviteIndividualUsers extends ConsumerWidget {
  final String roomId;

  const InviteIndividualUsers({super.key, required this.roomId});

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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              L10n.of(context).inviteIndividualUsersDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _buildSearchTextField(context, ref),
            const SizedBox(height: 10),
            _buildUserDirectInvite(ref),
            if (ref.watch(searchValueProvider) == null ||
                ref.watch(searchValueProvider)?.isEmpty == true)
              _buildSuggestedUserList(context, ref)
            else
              _buildFoundUserList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTextField(BuildContext context, WidgetRef ref) {
    final searchTextCtrl = ref.watch(searchController);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: searchTextCtrl,
        decoration: InputDecoration(
          prefixIcon: const Icon(Atlas.magnifying_glass_thin),
          hintText: L10n.of(context).searchUser,
        ),
        onChanged: (String value) {
          ref.read(searchValueProvider.notifier).update((state) => value);
        },
      ),
    );
  }

  Widget _buildUserDirectInvite(WidgetRef ref) {
    final searchValue = ref.watch(searchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      final cleaned = searchValue!.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            if (userNameRegExp.hasMatch(cleaned))
              DirectInvite(roomId: roomId, userId: cleaned),
            if (noAtUserNameRegExp.hasMatch(cleaned))
              DirectInvite(roomId: roomId, userId: '@$cleaned'),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSuggestedUserList(BuildContext context, WidgetRef ref) {
    final suggestedUsers =
        ref.watch(filteredSuggestedUsersProvider(roomId)).valueOrNull;
    if (suggestedUsers == null || suggestedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              L10n.of(context).suggestedUsers,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: suggestedUsers.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final user = suggestedUsers[index];
                return _buildSuggestedUserItem(ref, user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedUserItem(WidgetRef ref, FoundUser user) {
    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    return Card(
      child: ListTile(
        title: Text(user.avatarInfo.displayName ?? user.userId),
        subtitle:
            user.avatarInfo.displayName != null ? Text(user.userId) : null,
        leading: ActerAvatar(
          options: AvatarOptions.DM(
            user.avatarInfo,
          ),
        ),
        trailing: room != null
            ? UserStateButton(
                userId: user.userId,
                room: room,
              )
            : null,
      ),
    );
  }

  Widget _buildFoundUserList(BuildContext context, WidgetRef ref) {
    final usersLoader = ref.watch(searchResultProvider);
    if (usersLoader.hasValue) {
      final value = usersLoader.value;
      if (value != null) {
        if (value.isNotEmpty) {
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    L10n.of(context).usersfoundDirectory,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.builder(
                    itemCount: value.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) => UserBuilder(
                      userId: value[index].userId().toString(),
                      roomId: roomId,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
    return EmptyState(
      title: L10n.of(context).noUserFoundTitle,
      subtitle: L10n.of(context).noUserFoundSubtitle,
      image: 'assets/images/empty_activity.svg',
    );
  }
}
