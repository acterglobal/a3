import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileProvider = FutureProvider<UserProfile>(
  (ref) async {
    final userProfile =
        await ref.read(homeStateProvider.notifier).client.getUserProfile();
    return userProfile;
  },
);

class UserAvatarWidget extends ConsumerWidget {
  final bool isExtendedRail;
  const UserAvatarWidget({required this.isExtendedRail, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(homeStateProvider.notifier).client;
    final userProfile = ref.watch(userProfileProvider);
    if (client.isGuest()) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/login'),
        child: TextAvatar(
          backgroundColor: Colors.grey,
          text: 'G',
          numberLetters: 1,
          shape: Shape.Circular,
          upperCase: true,
        ),
      );
    }
    return userProfile.when(
      data: (data) {
        return Row(
          mainAxisAlignment: isExtendedRail
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            CustomAvatar(
              uniqueKey: client.userId().toString(),
              radius: 24,
              isGroup: false,
              cacheHeight: 120,
              cacheWidth: 120,
              avatar: data.getAvatar(),
              displayName: data.getDisplayName(),
              stringName: data.getDisplayName() ?? '',
            ),
            if (isExtendedRail)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  data.getDisplayName() ?? '',
                  style: SideMenuAndProfileTheme.sideMenuProfileStyle,
                ),
              )
          ],
        );
      },
      error: (error, _) => const Text('Couldn\'t load avatar'),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppCommonTheme.primaryColor,
        ),
      ),
    );
  }
}
