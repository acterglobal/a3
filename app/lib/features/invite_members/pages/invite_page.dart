import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InvitePage extends ConsumerWidget {
  final String roomId;

  const InvitePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      actions: [
        _buildPendingActionButton(context),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildPendingActionButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        context.pushNamed(
          Routes.invitePending.name,
          queryParameters: {'roomId': roomId.toString()},
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(8.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_add_alt_1,
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            L10n.of(context).pending,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildInviteHeader(context, ref),
          const SizedBox(height: 20),
          _buildInviteMethods(context),
          const SizedBox(height: 20),
          divider(context),
          const SizedBox(height: 30),
          _buildInviteFromCode(context),
        ],
      ),
    );
  }

  Widget divider(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 1,
        color: Theme.of(context).colorScheme.neutral5,
      ),
    );
  }

  Widget _buildInviteHeader(BuildContext context, WidgetRef ref) {
    final roomItem =
        ref.watch(briefRoomItemWithMembershipProvider(roomId)).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (roomItem != null)
          Column(
            children: [
              ActerAvatar(
                mode: DisplayMode.Space,
                avatarInfo: AvatarInfo(
                  uniqueId: roomItem.roomId,
                  displayName: roomItem.roomProfileData.displayName,
                  avatar: roomItem.roomProfileData.getAvatarImage(),
                ),
                size: 50,
              ),
              const SizedBox(height: 10),
              Text(roomItem.roomProfileData.displayName ?? ''),
            ],
          ),
        const SizedBox(height: 10),
        Text(
          L10n.of(context).invite,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          L10n.of(context).spaceInviteDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInviteMethods(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MenuItemWidget(
              iconData: Icons.person_add_alt_1,
              title: L10n.of(context).inviteSpaceMembersTitle,
              subTitle: L10n.of(context).inviteSpaceMembersSubtitle,
              onTap: () => EasyLoading.showInfo(L10n.of(context).comingSoon),
            ),
            MenuItemWidget(
              iconData: Icons.person_add_alt_1,
              title: L10n.of(context).inviteIndividualUsersTitle,
              subTitle: L10n.of(context).inviteIndividualUsersSubtitle,
              onTap: () => context.pushNamed(
                Routes.inviteIndividual.name,
                queryParameters: {'roomId': roomId.toString()},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteFromCode(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.neutral6,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L10n.of(context).inviteJoinActer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              L10n.of(context).inviteJoinActerDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ActerPrimaryActionButton(
              onPressed: () =>
                  EasyLoading.showInfo(L10n.of(context).comingSoon),
              child: Text(L10n.of(context).generateInviteCode),
            ),
          ],
        ),
      ),
    );
  }
}
