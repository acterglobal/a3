import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppbar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Settings'),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _userProfileUI(),
          const SettingsMenu(),
        ],
      ),
    );
  }

  Widget _userProfileUI() {
    return Consumer(
      builder: (context, ref, child) {
        final account = ref.watch(accountProfileProvider);
        final size = MediaQuery.of(context).size;
        final shouldGoNotNamed = isDesktop && size.width > 770;
        return account.when(
          data: (data) {
            final userId = data.account.userId().toString();
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: () => shouldGoNotNamed
                    ? context.goNamed(Routes.myProfile.name)
                    : context.pushNamed(Routes.myProfile.name),
                leading: ActerAvatar(
                  mode: DisplayMode.DM,
                  avatarInfo: AvatarInfo(
                    uniqueId: userId,
                    avatar: data.profile.getAvatarImage(),
                    displayName: data.profile.displayName,
                  ),
                ),
                title: Text(
                  data.profile.displayName ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  userId,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            );
          },
          error: (e, trace) => Text('error: $e'),
          loading: () => const Text('loading'),
        );
      },
    );
  }
}
