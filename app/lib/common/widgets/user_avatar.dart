import 'package:acter/common/providers/common_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAvatarWidget extends ConsumerWidget {
  final double size;

  const UserAvatarWidget({required this.size, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAvatarInfo = ref.watch(accountAvatarInfoProvider);
    return ActerAvatar(
      options: AvatarOptions.DM(accountAvatarInfo, size: size),
    );
  }
}
