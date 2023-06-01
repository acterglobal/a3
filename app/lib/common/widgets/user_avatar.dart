import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _UserItem {
  Future<FfiBufferUint8> avatar;
  String? displayName;

  _UserItem({
    required this.avatar,
    required this.displayName,
  });
}

final _userItemProvider = FutureProvider<_UserItem>((ref) async {
  final client = ref.watch(clientProvider);
  var profile = client!.getUserProfile();
  DispName name = await profile.getDisplayName();
  return _UserItem(
    avatar: profile.getAvatar(),
    displayName: name.text(),
  );
});

class UserAvatarWidget extends ConsumerWidget {
  const UserAvatarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final userItem = ref.watch(_userItemProvider);
    return userItem.when(
      data: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActerAvatar(
              mode: DisplayMode.User,
              uniqueId: client.userId().toString(),
              size: 20,
              avatarProviderFuture: remapToImage(
                data.avatar,
                cacheHeight: 54,
              ),
              displayName: data.displayName,
            ),
          ],
        );
      },
      error: (error, stackTrace) => const Text("Couldn't load avatar"),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
