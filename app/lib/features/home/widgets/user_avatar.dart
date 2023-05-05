import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter/features/home/states/client_state.dart';
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
            UserAvatar(
              uniqueKey: client.userId().toString(),
              radius: 20,
              isGroup: false,
              cacheHeight: 120,
              cacheWidth: 120,
              avatar: data.getAvatar(),
              displayName: data.getDisplayName(),
              stringName: data.getDisplayName() ?? '',
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
