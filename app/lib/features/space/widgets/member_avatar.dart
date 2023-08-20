import 'package:acter/common/providers/common_providers.dart';
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
    final profile = ref.watch(memberProfileProvider(userId));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.neutral4),
            shape: BoxShape.circle,
          ),
          child: profile.when(
            data: (data) => ActerAvatar(
              mode: DisplayMode.User,
              uniqueId: userId,
              size: data.hasAvatar() ? 18 : 36,
              avatar: data.getAvatarImage(),
              displayName: data.displayName,
            ),
            error: (err, stackTrace) {
              debugPrint("Couldn't load avatar");
              return ActerAvatar(
                mode: DisplayMode.User,
                uniqueId: userId,
                size: 36,
                displayName: userId,
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}
