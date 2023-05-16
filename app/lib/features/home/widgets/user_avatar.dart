import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final client = ref.watch(clientProvider);
  return await client!.getUserProfile();
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
                data.getAvatar(),
                cacheHeight: 54,
              ),
              displayName: data.getDisplayName(),
            ),
          ],
        );
      },
      error: (error, _) => const Text('Couldn\'t load avatar'),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
