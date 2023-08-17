import 'package:acter/common/providers/common_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentionProfileBuilder extends ConsumerWidget {
  final String authorId;
  final String title;

  const MentionProfileBuilder({
    Key? key,
    required this.authorId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionProfile = ref.watch(memberProfileProvider(authorId));
    return mentionProfile.when(
      data: (profile) {
        return ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: authorId,
          avatar: profile.getAvatarImage(),
          displayName: title,
          size: profile.hasAvatar() ? 18 : 36,
        );
      },
      error: (e, st) {
        debugPrint('ERROR loading avatar due to $e');
        return ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: authorId,
          displayName: title,
          size: 36,
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}
