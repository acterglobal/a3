import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_avatar/acter_avatar.dart';

class MemberAvatar extends ConsumerWidget {
  final Member member;

  const MemberAvatar({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = member.userId().toString();
    final profile = ref.watch(memberProfileProvider(member));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.neutral4),
        shape: BoxShape.circle,
      ),
      child: profile.when(
        data: (data) => ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            avatar: data.getAvatarImage(),
            displayName: data.displayName,
          ),
          size: 18,
        ),
        error: (err, stackTrace) {
          debugPrint("Couldn't load avatar");
          return ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: userId,
              displayName: userId,
            ),
            size: 18,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
