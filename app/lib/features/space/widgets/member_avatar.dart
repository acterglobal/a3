import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/widgets/custom_avatar.dart';

final membersProfileProvider =
    FutureProvider.family<UserProfile, Member>((ref, member) async {
  return await member.getProfile();
});

class MemberAvatar extends ConsumerWidget {
  final Member member;
  const MemberAvatar({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(membersProfileProvider(member));

    return profile.when(
      data: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomAvatar(
              uniqueKey: member.userId().toString(),
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
