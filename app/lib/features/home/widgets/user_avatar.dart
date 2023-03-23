import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final client = ref.watch(homeStateProvider);
  return await client!.getUserProfile();
});

class UserAvatarWidget extends ConsumerWidget {
  const UserAvatarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(homeStateProvider)!;
    final userProfile = ref.watch(userProfileProvider);
    if (client.isGuest()) {
      return GestureDetector(
        onTap: () => context.go('/login'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 40,
              height: 40,
              child: TextAvatar(
                backgroundColor: Colors.grey,
                text: 'G',
                numberLetters: 1,
                shape: Shape.Circular,
                upperCase: true,
              ),
            ),
          ],
        ),
      );
    }
    return userProfile.when(
      data: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomAvatar(
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
