import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildAppbar(context),
        Expanded(child: _buildBody(context, ref)),
      ],
    );
  }

  AppBar _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Text(L10n.of(context).settings),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _userProfileUI(context, ref),
          const SettingsMenu(),
        ],
      ),
    );
  }

  Widget _userProfileUI(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProfileProvider);
    final size = MediaQuery.of(context).size;
    final shouldGoNotNamed = size.width > 770;
    return account.when(
      data: (data) {
        final userId = data.account.userId().toString();
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(L10n.of(context).editProfile),
              ),
            ],
          ),
        );
      },
      error: (e, trace) => Text('error: $e'),
      loading: () => userProfileMenuSkeletonUI(context),
    );
  }

  Widget userProfileMenuSkeletonUI(BuildContext context) {
    return Skeletonizer(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context).displayName),
                  Text(L10n.of(context).username),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
