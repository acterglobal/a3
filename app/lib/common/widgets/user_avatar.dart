import 'package:acter/features/home/states/client_state.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show FfiBufferUint8;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserItem {
  Future<FfiBufferUint8> avatar;
  String? displayName;

  UserItem({
    required this.avatar,
    required this.displayName,
  });
}

final userProfileProvider = FutureProvider<UserItem>((ref) async {
  final client = ref.watch(clientProvider);
  var profile = client!.getUserProfile();
  return UserItem(
    avatar: profile.getAvatar(),
    displayName: await profile.getDisplayName(),
  );
});

class UserAvatarWidget extends ConsumerWidget {
  const UserAvatarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final userProfile = ref.watch(userProfileProvider);
    return userProfile.when(
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
