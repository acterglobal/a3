import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAvatarWidget extends ConsumerWidget {
  final double size;
  const UserAvatarWidget({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final accountProfile = ref.watch(accountProfileProvider);
    return accountProfile.when(
      data: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActerAvatar(
              mode: DisplayMode.DM,
              avatarInfo: AvatarInfo(
                uniqueId: client.userId().toString(),
                displayName: data.profile.displayName,
                avatar: data.profile.getAvatarImage(),
              ),
              size: size,
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
