import 'dart:typed_data';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::invite::providers');

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

final searchController = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
    ref.read(searchValueProvider.notifier).state = null;
  });
  return controller;
});

final searchValueProvider = StateProvider<String?>((ref) => null);

final searchResultProvider = FutureProvider<List<UserProfile>>((ref) async {
  final newSearchValue = ref.watch(searchValueProvider);
  if (newSearchValue == null || newSearchValue.isEmpty) {
    return [];
  }
  try {
    await ref.debounce(const Duration(milliseconds: 300));
  } catch (e) {
    // ignore we got cancelled
    return [];
  }
  final client = ref.watch(alwaysClientProvider);
  return (await client.searchUsers(newSearchValue)).toList();
});

final suggestedUsersProvider = FutureProvider.family<List<UserProfile>, String>(
  (ref, roomId) async {
    final client = ref.watch(alwaysClientProvider);
    return (await client.suggestedUsersToInvite(roomId)).toList();
  },
);

final filteredSuggestedUsersProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, roomId) async {
  final newSearchValue = ref.watch(searchValueProvider);
  final suggestedUsers =
      ref.watch(suggestedUsersProvider(roomId)).valueOrNull ?? [];
  if (newSearchValue == null || newSearchValue.isEmpty) {
    // no search value: shows all
    return suggestedUsers;
  }

  final loweredSearchValue = newSearchValue.toLowerCase();

  return suggestedUsers.where(
    (profile) {
      if (profile
          .userId()
          .toString()
          .toLowerCase()
          .contains(loweredSearchValue)) {
        return true;
      }
      return profile
              .getDisplayName()
              ?.toLowerCase()
              .contains(loweredSearchValue) ==
          true;
    },
  ).toList();
});
