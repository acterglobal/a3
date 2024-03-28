import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class UserAvatarWidget extends ConsumerWidget {
  final double size;

  const UserAvatarWidget({
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final userId = client.userId().toString();
    final accountProfile = ref.watch(accountProfileProvider);
    return accountProfile.when(
      data: (data) => ActerAvatar(
        mode: DisplayMode.DM,
        size: size,
        avatarInfo: AvatarInfo(
          uniqueId: userId,
          displayName: data.profile.displayName,
          avatar: data.profile.getAvatarImage(),
        ),
      ),
      error: (error, stackTrace) => Text(L10n.of(context).couldNotLoadAvatar),
      loading: () => Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          size: size,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
          ),
        ),
      ),
    );
  }
}
