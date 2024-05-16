import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/user_builder.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/features/invite_members/providers/invite_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InviteIndividualUsers extends ConsumerStatefulWidget {
  final String roomId;

  const InviteIndividualUsers({super.key, required this.roomId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InviteIndividualUsersState();
}

class _InviteIndividualUsersState extends ConsumerState<InviteIndividualUsers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(L10n.of(context).inviteIndividualUsersTitle),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
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
            _buildSearchTextField(),
            const SizedBox(height: 10),
            _buildUserDirectInvite(),
            if (ref.watch(searchValueProvider) == null ||
                ref.watch(searchValueProvider)?.isEmpty == true)
              _buildSuggestedUserList()
            else
              _buildFoundUserList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTextField() {
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

  Widget _buildUserDirectInvite() {
    final searchValue = ref.watch(searchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      final cleaned = searchValue!.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            if (userNameRegExp.hasMatch(cleaned))
              DirectInvite(roomId: widget.roomId, userId: cleaned),
            if (noAtUserNameRegExp.hasMatch(cleaned))
              DirectInvite(roomId: widget.roomId, userId: '@$cleaned'),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSuggestedUserList() {
    final suggestedUsers =
        ref.watch(filteredSuggestedUsersProvider(widget.roomId)).valueOrNull;
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
                return _buildSuggestedUserItem(user);
              },
            ),
          ),
          _buildDoneButton(),
        ],
      ),
    );
  }

  Widget _buildSuggestedUserItem(FoundUser user) {
    final room = ref.watch(briefRoomItemWithMembershipProvider(widget.roomId));
    return Card(
      child: ListTile(
        title: Text(user.profile.displayName ?? user.userId),
        subtitle: user.profile.displayName != null ? Text(user.userId) : null,
        leading: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: user.userId,
            displayName: user.profile.displayName,
            avatar: user.profile.getAvatarImage(),
          ),
        ),
        trailing: UserStateButton(
          userId: user.userId,
          room: room.valueOrNull!.room!,
        ),
      ),
    );
  }

  Widget _buildFoundUserList() {
    final foundUsers = ref.watch(searchResultProvider);
    if (foundUsers.hasValue && foundUsers.value!.isNotEmpty) {
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
                itemCount: foundUsers.value!.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return foundUsers.when(
                    data: (data) => UserBuilder(
                      profile: data[index],
                      roomId: widget.roomId,
                    ),
                    error: (err, stackTrace) =>
                        Text(L10n.of(context).error(err)),
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Skeletonizer(
                        child: Text(L10n.of(context).loading),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildDoneButton(),
          ],
        ),
      );
    }
    return EmptyState(
      title: L10n.of(context).noUserFoundTitle,
      subtitle: L10n.of(context).noUserFoundSubtitle,
      image: 'assets/images/empty_activity.svg',
    );
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ActerPrimaryActionButton(
        onPressed: () => context.pop(),
        child: Text(L10n.of(context).done),
      ),
    );
  }
}
