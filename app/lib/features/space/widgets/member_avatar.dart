import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberAvatar extends ConsumerWidget {
  final Member member;
  late final String _userId;

  MemberAvatar({Key? key, required this.member}) : super(key: key) {
    // get user id in advance to avoid error on release runtime
    _userId = member.userId().toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider(member));
    return profile.when(
      data: (data) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.neutral4,
                ),
                shape: BoxShape.circle,
              ),
              child: ActerAvatar(
                mode: DisplayMode.User,
                uniqueId: _userId,
                size: 20,
                avatar: data.getAvatarImage(),
                displayName: data.displayName,
              ),
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
