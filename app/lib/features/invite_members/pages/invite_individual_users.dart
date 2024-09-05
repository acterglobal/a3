import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/user_builder.dart';
import 'package:acter/features/invite_members/providers/invite_providers.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __SearchFieldState();
}

class __SearchFieldState extends ConsumerState<_SearchField> {
  final searchTextCtrl = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchTextCtrl.text = ref.read(searchValueProvider) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: searchTextCtrl,
        decoration: InputDecoration(
          prefixIcon: const Icon(Atlas.magnifying_glass_thin),
          hintText: L10n.of(context).searchUser,
          suffix: ref.watch(searchValueProvider)?.isNotEmpty == true
              ? InkWell(
                  onTap: () {
                    ref.read(searchValueProvider.notifier).state = null;
                    searchTextCtrl.clear();
                  },
                  child: const Icon(
                    Atlas.xmark_circle_thin,
                  ),
                )
              : null,
        ),
        onChanged: (String value) {
          ref.read(searchValueProvider.notifier).update((state) => value);
        },
      ),
    );
  }
}

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              L10n.of(context).inviteIndividualUsersDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const _SearchField(),
            const SizedBox(height: 10),
            _buildUserDirectInvite(ref),
            Expanded(
              child: _renderResults(context, ref),
            ),
          ],
        ),
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

  Widget _renderResults(BuildContext context, WidgetRef ref) {
    final suggestedUsers =
        ref.watch(filteredSuggestedUsersProvider(null)).valueOrNull ?? [];

    final foundUsers = ref.watch(searchResultProvider).valueOrNull ?? [];

    if (suggestedUsers.isEmpty && foundUsers.isEmpty) {
      // nothing found
      return Center(
        child: EmptyState(
          title: L10n.of(context).noUserFoundTitle,
          subtitle: L10n.of(context).noUserFoundSubtitle,
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

        final userWidget = UserBuilder(
          userId: user.userId().toString(),
          roomId: roomId,
          userProfile: user,
          includeSharedRooms: showRooms,
        );
        if (position == 0 && suggestedUsers.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Text(
                  L10n.of(context).suggestedUsers,
                  style: Theme.of(context).textTheme.titleSmall,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Text(
                  L10n.of(context).usersfoundDirectory,
                  style: Theme.of(context).textTheme.titleSmall,
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
