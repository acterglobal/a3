import 'dart:typed_data';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

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

class InviteToSpaceDialog extends ConsumerWidget {
  final String spaceId;
  const InviteToSpaceDialog({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(briefSpaceItemWithMembershipProvider(spaceId));
    final _searchTextCtrl = ref.watch(searchController);
    final suggestedUsers =
        ref.watch(filteredSuggestedUsersProvider(spaceId)).valueOrNull;
    final foundUsers = ref.watch(searchResultProvider);
    final children = [];

    if (suggestedUsers != null && suggestedUsers.isNotEmpty) {
      children.add(const SliverToBoxAdapter(
        child: Text('Suggested Users'),
      ));
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
                ),
              );
            },
            childCount: suggestedUsers.length,
          ),
        ),
      );
    }

    if (foundUsers.hasValue && foundUsers.value!.isNotEmpty) {
      children.add(const SliverToBoxAdapter(
        child: Text('Users found in public directory'),
      ));
      children.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final e = foundUsers.value![index];
              final userId = e.userId().toString();
              return Consumer(
                builder: (context, ref, child) {
                  final avatarProv = ref.watch(userAvatarProvider(e));
                  final displayName = ref.watch(displayNameProvider(e));
                  return Card(
                    child: ListTile(
                      title: Text(displayName.valueOrNull ?? userId),
                      subtitle:
                          displayName.valueOrNull != null ? Text(userId) : null,
                      leading: ActerAvatar(
                        mode: DisplayMode.User,
                        uniqueId: userId,
                        displayName: displayName.valueOrNull,
                        avatar: avatarProv.valueOrNull,
                      ),
                    ),
                  );
                },
              );
            },
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
            title: Text(
              'Invite to ${space.spaceProfileData.displayName}',
            ),
          ),
          error: (error, stackTrace) => AppBar(title: Text('Error: $error')),
          loading: () => AppBar(
            title: const Text('Invite user'),
          ),
        ),
        // title: const Text('Invite User to')),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: TextField(
                  controller: _searchTextCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Atlas.magnifying_glass_thin,
                      color: Colors.white,
                    ),
                    labelText: 'search user',
                  ),
                  onChanged: (String value) async {
                    ref.read(searchValueProvider.notifier).state = value;
                  },
                ),
              ),
            ),
            ...children
          ],
        ),
      ),
    );
  }
}
