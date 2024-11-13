import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/deep_linking/widgets/qr_code_button.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsPage extends ConsumerWidget {
  final bool isFullPage;

  const SettingsPage({
    this.isFullPage = false,
    super.key,
  });

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
      automaticallyImplyLeading: !context.isLargeScreen,
      title: Text(L10n.of(context).settings),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _userProfileUI(context, ref),
          SettingsMenu(isFullPage: isFullPage),
        ],
      ),
    );
  }

  Widget _userProfileUI(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final accountInfo = ref.watch(accountAvatarInfoProvider);
    final shouldGoReplacement = context.isLargeScreen;
    final userId = account.userId().toString();
    return InkWell(
      onTap: () => shouldGoReplacement
          ? context.pushReplacementNamed(Routes.myProfile.name)
          : context.pushNamed(Routes.myProfile.name),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ListTile(
              leading: ActerAvatar(
                options: AvatarOptions.DM(accountInfo),
              ),
              title: Text(
                accountInfo.displayName ?? '',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                userId,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: QrCodeButton(
                qrCodeData: 'matrix:u/${userId.substring(1)}?action=chat',
                qrTitle: ListTile(
                  leading: ActerAvatar(
                    options: AvatarOptions.DM(accountInfo),
                  ),
                  title: Text(
                    accountInfo.displayName ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    userId,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(L10n.of(context).editProfile),
            ),
          ],
        ),
      ),
    );
  }

  Widget userProfileMenuSkeletonUI(BuildContext context) {
    final lang = L10n.of(context);
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
                  Text(lang.displayName),
                  Text(lang.username),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
