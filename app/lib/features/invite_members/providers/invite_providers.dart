import 'dart:typed_data';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:extension_nullable/extension_nullable.dart';
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
  _log.info('starting search for $newSearchValue');
  if (newSearchValue == null || newSearchValue.length < 3) {
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

class FoundUser {
  final String userId;
  final AvatarInfo avatarInfo;

  const FoundUser({
    required this.userId,
    required this.avatarInfo,
  });
}

final suggestedUsersProvider = FutureProvider.family<List<FoundUser>, String>(
  (ref, roomId) async {
    final client = ref.watch(alwaysClientProvider);
    final suggested = (await client.suggestedUsersToInvite(roomId)).toList();
    List<FoundUser> ret = [];
    for (final user in suggested) {
      String? displayName = user.getDisplayName();
      MemoryImage? avatarData;
      if (user.hasAvatar()) {
        try {
          final avatar = await user.getAvatar(null);
          avatarData = avatar
              .data()
              .map((p0) => MemoryImage(Uint8List.fromList(p0.asTypedList())));
        } catch (e, s) {
          _log.severe('failure fetching avatar', e, s);
        }
      }
      ret.add(
        FoundUser(
          userId: user.userId().toString(),
          avatarInfo: AvatarInfo(
            uniqueId: user.userId().toString(),
            displayName: displayName,
            avatar: avatarData,
          ),
        ),
      );
    }
    return ret;
  },
);

final filteredSuggestedUsersProvider =
    FutureProvider.family<List<FoundUser>, String>(
  (ref, roomId) async {
    final fullList = await ref.watch(suggestedUsersProvider(roomId).future);
    final searchTerm = ref.watch(searchValueProvider);
    if (searchTerm == null || searchTerm.isEmpty) {
      return fullList;
    }
    final lowered = searchTerm.toLowerCase();
    return fullList.where((el) {
      if (el.userId.toLowerCase().contains(lowered)) return true;
      return el.avatarInfo.displayName?.toLowerCase().contains(lowered) == true;
    }).toList();
  },
);
