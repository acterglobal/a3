import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/dotted_border_widget.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::invite_page');

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _roomProfileDetailsUI(ref),
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

  Widget _roomProfileDetailsUI(WidgetRef ref) {
    final roomProfile = ref.watch(roomProfileDataProvider(roomId)).valueOrNull;
    return Column(
      children: [
        ActerAvatar(
          mode: DisplayMode.Space,
          avatarInfo: AvatarInfo(
            uniqueId: roomId,
            displayName: roomProfile?.displayName,
            avatar: roomProfile?.getAvatarImage(),
          ),
          size: 50,
        ),
        const SizedBox(height: 10),
        Text(roomProfile?.displayName ?? ''),
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
              iconData: Icons.people_alt_outlined,
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

  Widget _buildInviteFromCode(BuildContext context, WidgetRef ref) {
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
            _inviteCodeUI(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _inviteCodeUI(BuildContext context, WidgetRef ref) {
    var inviteCode =
        ref.watch(inviteCodeForSelectRoomOnly(roomId)).valueOrNull?.token();
    if (inviteCode != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DottedBorderWidget(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteCode,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: inviteCode),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ActerInlineTextButton(
              onPressed: () => _inactiveInviteCode(context, ref, inviteCode),
              child: Text(
                L10n.of(context).inactivate,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ActerPrimaryActionButton(
            onPressed: () => context.pushNamed(
              Routes.shareInviteCode.name,
              queryParameters: {
                'inviteCode': inviteCode,
                'roomId': roomId,
              },
            ),
            child: Text(L10n.of(context).share),
          ),
        ],
      );
    }
    return ActerPrimaryActionButton(
      onPressed: () => generateNewInviteCode(context, ref),
      child: Text(L10n.of(context).generateInviteCode),
    );
  }

  Future<void> generateNewInviteCode(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      EasyLoading.show(status: L10n.of(context).generateInviteCode);
      await newSuperInviteForRooms(ref, [roomId]);
      ref.invalidate(superInvitesProvider);
      EasyLoading.dismiss();
    } catch (error) {
      EasyLoading.dismiss();
      _log.severe('Invite code activation failed', error);
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).activateInviteCodeFailed(error),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _inactiveInviteCode(
    BuildContext context,
    WidgetRef ref,
    String token,
  ) async {
    final bool? confirm = await showAdaptiveDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(L10n.of(context).inactivateCode),
          content: Text(
            L10n.of(context).doYouWantToInactiveInviteCode,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(
                L10n.of(context).no,
              ),
            ),
            ActerDangerActionButton(
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop(true);
              },
              child: Text(
                L10n.of(context).inactivate,
              ),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) {
      return;
    }
    EasyLoading.show(status: L10n.of(context).inactivateCode);
    try {
      final provider = ref.watch(superInvitesProvider);
      await provider.delete(token);
      ref.invalidate(superInvitesProvider);
      EasyLoading.dismiss();
      ref.invalidate(superInvitesProvider);
    } catch (err) {
      EasyLoading.dismiss();
      _log.severe('Invite code creation failed', err);
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).inactivateInviteCodeFailed(err),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
