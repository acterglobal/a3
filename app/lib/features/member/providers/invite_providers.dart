import 'package:acter/common/extensions/ref_debounce.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userNameRegExp = RegExp(
  r'@\S+:\S+.\S+$',
  unicode: true,
  caseSensitive: false,
);

final noAtUserNameRegExp = RegExp(
  r'\S+:\S+.\S+$',
  unicode: true,
  caseSensitive: false,
);

final userSearchValueProvider = StateProvider<String?>((ref) => null);

final searchResultProvider = FutureProvider<List<UserProfile>>((ref) async {
  final newSearchValue = ref.watch(userSearchValueProvider);
  if (newSearchValue == null || newSearchValue.isEmpty) {
    return [];
  }
  try {
    await ref.debounce(const Duration(milliseconds: 300));
  } catch (e) {
    // ignore we got cancelled
    return [];
  }
  final client = await ref.watch(alwaysClientProvider.future);
  return (await client.searchUsers(newSearchValue)).toList();
});

final suggestedUsersProvider =
    FutureProvider.family<List<UserProfile>, String?>((ref, roomId) async {
      final client = await ref.watch(alwaysClientProvider.future);
      return (await client.suggestedUsers(roomId)).toList();
    });

final filteredSuggestedUsersProvider =
    FutureProvider.family<List<UserProfile>, String?>((ref, roomId) async {
      final newSearchValue = ref.watch(userSearchValueProvider);
      final suggestedUsers =
          ref.watch(suggestedUsersProvider(roomId)).valueOrNull ?? [];
      if (newSearchValue == null || newSearchValue.isEmpty) {
        // no search value: shows all
        return suggestedUsers;
      }

      final loweredSearchValue = newSearchValue.toLowerCase();

      return suggestedUsers.where((profile) {
        if (profile.userId().toString().toLowerCase().contains(
          loweredSearchValue,
        )) {
          return true;
        }
        return profile.displayName()?.toLowerCase().contains(
              loweredSearchValue,
            ) ==
            true;
      }).toList();
    });

/// Provider for getting the invitations manager for a specific task
final taskInvitationsManagerProvider = FutureProvider.family<ObjectInvitationsManager, Task>(
  (ref, task) => task.invitations(),
);

/// Provider for getting the list of invited users for a task
final taskInvitedUsersProvider = FutureProvider.family<List<String>, Task>(
  (ref, task) async {
    final manager = await ref.watch(taskInvitationsManagerProvider(task).future);
    return manager.invited().map((data) => data.toString()).toList();
  },
);

/// Provider for checking if a user is invited to a task
final isUserInvitedToTaskProvider = FutureProvider.family<bool, (Task, String)>(
  (ref, params) async {
    final (task, userId) = params;
    final manager = await ref.watch(taskInvitationsManagerProvider(task).future);
    return manager.isInvited();
  },
);

/// Provider for inviting a user to a task
final inviteUserToTaskProvider = FutureProvider.family<String, (Task, String)>(
  (ref, params) async {
    final (task, userId) = params;
    final manager = await ref.watch(taskInvitationsManagerProvider(task).future);
    return await manager.invite(userId);
  },
);
