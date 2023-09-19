import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvatarBuilder extends ConsumerWidget {
  final String userId;

  const AvatarBuilder({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberProfile = ref.watch(memberProfileByIdProvider(userId));
    return memberProfile.when(
      data: (profile) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: userId,
            displayName: profile.displayName ?? userId,
            avatar: profile.getAvatarImage(),
            size: profile.hasAvatar() ? 14 : 28,
          ),
        );
      },
      error: (e, st) {
        debugPrint('ERROR loading avatar due to $e');
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            uniqueId: userId,
            displayName: userId,
            mode: DisplayMode.User,
            size: 28,
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}
