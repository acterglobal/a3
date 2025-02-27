import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/member/widgets/member_info_skeleton.dart';
import 'package:acter/features/users/widgets/message_user_button.dart';
import 'package:acter/features/users/providers/user_profile_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:acter/common/extensions/options.dart';

final _log = Logger('a3::user::user_info_drawer');

class _UserInfoDrawerInner extends ConsumerWidget {
  final UserProfile? profile;
  final String userId;

  const _UserInfoDrawerInner({required this.userId, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo =
        profile.map((profile) => ref.watch(userAvatarInfoProvider(profile))) ??
        AvatarInfo(uniqueId: userId);
    final displayName = avatarInfo.displayName;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildAvatarUI(context, avatarInfo),
            const SizedBox(height: 20),
            if (displayName != null) Center(child: Text(displayName)),
            const SizedBox(height: 20),
            _buildUserName(context),
            const SizedBox(height: 20),
            ..._buildMenu(context, ref),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenu(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final myUserId = ref.watch(myUserIdStrProvider);
    final itsMe = userId == myUserId;
    if (itsMe) {
      return [Center(child: Text(lang.itsYou)), const SizedBox(height: 30)];
    }

    return [
      if (profile != null) MessageUserButton(userId: userId, profile: profile!),
    ];
  }

  Widget _buildAvatarUI(BuildContext context, AvatarInfo memberAvatarInfo) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            width: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        child: ActerAvatar(
          options: AvatarOptions.DM(
            AvatarInfo(
              uniqueId: userId,
              avatar: memberAvatarInfo.avatar,
              displayName: memberAvatarInfo.displayName,
            ),
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildUserName(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context); // close the drawer
        await Clipboard.setData(ClipboardData(text: userId));
        if (!context.mounted) return;
        EasyLoading.showToast(L10n.of(context).usernameCopiedToClipboard);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(userId),
          const SizedBox(width: 5),
          const Icon(Icons.copy_outlined),
        ],
      ),
    );
  }
}

class UserInfoDrawer extends ConsumerWidget {
  final String userId;

  const UserInfoDrawer({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberLoader = ref.watch(globalUserProfileProvider(userId));
    return memberLoader.when(
      data: (profile) => _UserInfoDrawerInner(profile: profile, userId: userId),
      error: (e, s) {
        _log.severe('Failed to load user', e, s);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(L10n.of(context).errorLoadingProfile(e)),
        );
      },
      loading: () => const MemberInfoSkeleton(),
    );
  }
}
