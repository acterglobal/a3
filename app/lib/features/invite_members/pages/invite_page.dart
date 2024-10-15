import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_profile_header.dart';
import 'package:acter/features/invite_members/widgets/invite_code_ui.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InvitePage extends ConsumerWidget {
  static const invitePageKey = Key('room-invite-page-key');
  final String roomId;

  const InvitePage({
    required this.roomId,
    super.key = invitePageKey,
  });

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
            Icons.person_outline_outlined,
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
          const Divider(indent: 70, endIndent: 70),
          const SizedBox(height: 30),
          if (ref.watch(hasSuperTokensAccess).valueOrNull == true)
            _buildInviteFromCode(context, ref),
        ],
      ),
    );
  }

  Widget _buildInviteHeader(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RoomProfileHeader(roomId: roomId),
        const SizedBox(height: 10),
        Text(
          lang.invite,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          lang.spaceInviteDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInviteMethods(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MenuItemWidget(
              iconData: Icons.people_alt_outlined,
              title: lang.inviteSpaceMembersTitle,
              subTitle: lang.inviteSpaceMembersSubtitle,
              onTap: () => context.pushNamed(
                Routes.inviteSpaceMembers.name,
                queryParameters: {'roomId': roomId.toString()},
              ),
            ),
            MenuItemWidget(
              iconData: Icons.person_add_alt_1,
              title: lang.inviteIndividualUsersTitle,
              subTitle: lang.inviteIndividualUsersSubtitle,
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

  Widget _buildInviteFromCode(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
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
              lang.inviteJoinActer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              lang.inviteJoinActerDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            InviteCodeUI(roomId: roomId),
          ],
        ),
      ),
    );
  }
}
