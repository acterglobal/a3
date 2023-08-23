import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/space/widgets/user_builder.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchController = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
    ref.read(searchValueProvider.notifier).state = null;
  });
  return controller;
});
final searchValueProvider = StateProvider<String?>((ref) => null);

class FoundUser {
  final String userId;
  final ProfileData profile;
  const FoundUser({required this.userId, required this.profile});
}

final userAvatarProvider =
    FutureProvider.family<MemoryImage?, UserProfile>((ref, user) async {
  if (await user.hasAvatar()) {
    try {
      final data = (await user.getAvatar()).data();
      if (data != null) {
        return MemoryImage(data.asTypedList());
      }
    } catch (e) {
      debugPrint('failure fetching avatar $e');
    }
  }
  return null;
});

final displayNameProvider =
    FutureProvider.family<String?, UserProfile>((ref, user) async {
  return (await user.getDisplayName()).text();
});

final searchResultProvider = FutureProvider<List<UserProfile>>((ref) async {
  final newSearchValue = ref.watch(searchValueProvider);
  debugPrint('starting search for $newSearchValue');
  if (newSearchValue == null || newSearchValue.length < 3) {
    return [];
  }
  try {
    await ref.debounce(const Duration(milliseconds: 300));
  } catch (e) {
    // ignore we got cancelled
    return [];
  }
  final client = ref.read(clientProvider)!;
  return (await client.searchUsers(newSearchValue)).toList();
});

final suggestedUsersProvider =
    FutureProvider.family<List<FoundUser>, String>((ref, roomId) async {
  final client = ref.watch(clientProvider)!;
  final suggested = (await client.suggestedUsersToInvite(roomId)).toList();
  final List<FoundUser> ret = [];
  for (final user in suggested) {
    String? displayName = (await user.getDisplayName()).text();
    FfiBufferUint8? avatar;
    if (await user.hasAvatar()) {
      try {
        avatar = (await user.getAvatar()).data();
      } catch (e) {
        debugPrint('failure fetching avatar $e');
      }
    }
    final profile = ProfileData(displayName, avatar);
    ret.add(FoundUser(userId: user.userId().toString(), profile: profile));
  }
  return ret;
});

final filteredSuggestedUsersProvider =
    FutureProvider.family<List<FoundUser>, String>((ref, roomId) async {
  final fullList = await ref.watch(suggestedUsersProvider(roomId).future);
  final searchTerm = ref.watch(searchValueProvider);
  if (searchTerm == null || searchTerm.isEmpty) {
    return fullList;
  }

  final lowered = searchTerm.toLowerCase();

  return fullList.where((element) {
    if (element.userId.toLowerCase().contains(lowered)) {
      return true;
    }
    return (element.profile.displayName != null &&
        element.profile.displayName!.toLowerCase().contains(lowered));
  }).toList();
});

class UserEntry extends ConsumerWidget {
  final UserProfile user;
  const UserEntry({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}

class InviteToSpaceDialog extends ConsumerStatefulWidget {
  final String spaceId;
  const InviteToSpaceDialog({
    super.key,
    required this.spaceId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InviteToSpaceDialogState();
}

class _InviteToSpaceDialogState extends ConsumerState<InviteToSpaceDialog>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spaceId = widget.spaceId;
    final space = ref.watch(briefSpaceItemWithMembershipProvider(spaceId));
    final invited =
        ref.watch(spaceInvitedMembersProvider(spaceId)).valueOrNull ?? [];
    final searchTextCtrl = ref.watch(searchController);
    final suggestedUsers =
        ref.watch(filteredSuggestedUsersProvider(spaceId)).valueOrNull;
    final foundUsers = ref.watch(searchResultProvider);
    final searchValueNotifier = ref.watch(searchValueProvider.notifier);
    final children = [];

    if (suggestedUsers != null && suggestedUsers.isNotEmpty) {
      children.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'Suggested Users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      );
      children.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final e = suggestedUsers[index];
              return Card(
                child: ListTile(
                  title: Text(e.profile.displayName ?? e.userId),
                  subtitle:
                      e.profile.displayName != null ? Text(e.userId) : null,
                  leading: ActerAvatar(
                    mode: DisplayMode.User,
                    uniqueId: e.userId,
                    displayName: e.profile.displayName,
                    avatar: e.profile.getAvatarImage(),
                  ),
                  trailing: InviteButton(
                    userId: e.userId,
                    space: space.valueOrNull!.space!,
                    invited: isInvited(e.userId, invited),
                  ),
                ),
              );
            },
            childCount: suggestedUsers.length,
          ),
        ),
      );
    }

    if (foundUsers.hasValue && foundUsers.value!.isNotEmpty) {
      children.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'Users found in public directory',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      );
      children.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => foundUsers.when(
              data: (data) => UserBuilder(
                profile: data[index],
                spaceId: widget.spaceId,
              ),
              error: (err, stackTrace) => Text('Error: $err'),
              loading: () => const Text('Loading found user'),
            ),
            childCount: foundUsers.value!.length,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Scaffold(
        appBar: space.when(
          data: (space) => AppBar(
            title: Text('Invite to ${space.spaceProfileData.displayName}'),
            bottom: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              tabs: <Widget>[
                const Tab(
                  text: 'Invite',
                  icon: Icon(Atlas.paper_airplane_thin),
                ),
                Tab(
                  text: 'Pending Invites (${invited.length})',
                  icon: const Icon(Atlas.mailbox_thin),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => AppBar(title: Text('Error: $error')),
          loading: () => AppBar(
            title: const Text('Invite user'),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: TextField(
                      controller: searchTextCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Atlas.magnifying_glass_thin,
                          color: Colors.white,
                        ),
                        labelText: 'search user',
                      ),
                      onChanged: (String value) {
                        searchValueNotifier.state = value;
                      },
                    ),
                  ),
                ),
                ...children
              ],
            ),
            CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => UserBuilder(
                      profile: invited[index].getProfile(),
                      spaceId: widget.spaceId,
                    ),
                    childCount: invited.length,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
