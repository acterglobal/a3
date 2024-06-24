import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/dotted_border_widget.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::invite_members::invite_code');

class InviteCodeUI extends ConsumerStatefulWidget {
  final String roomId;
  const InviteCodeUI({super.key, required this.roomId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _InviteCodeUIState();
}

class _InviteCodeUIState extends ConsumerState<InviteCodeUI> {
  @override
  Widget build(BuildContext context) {
    var inviteCode = ref
        .watch(inviteCodeForSelectRoomOnly(widget.roomId))
        .valueOrNull
        ?.token();
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
                'roomId': widget.roomId,
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
      await newSuperInviteForRooms(ref, [widget.roomId]);
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
