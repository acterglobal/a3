import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

const redeemConfirmKey = Key('super-invite-redeem-confirm-btn');
const redeemInfoKey = Key('super-invites-redeem-info');

final _log = Logger('a3::super_invites::redeem');

class _ShowRedeemTokenDialog extends ConsumerWidget {
  final String token;
  const _ShowRedeemTokenDialog({required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoLoader = ref.watch(superInviteInfoProvider(token));
    return AlertDialog(
      title: Text(L10n.of(context).redeem),
      content: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            infoLoader.when(
              data: (info) => renderInfo(context, ref, info),
              error: (e, s) {
                _log.severe('Failed to load the super invite: $token', e, s);
                final errorStr = e.toString();
                if (errorStr.contains('error: [404]')) {
                  // Server doesn't yet support previewing
                  return Text(
                    L10n.of(context).superInvitesPreviewMissing(token),
                  );
                }
                if (errorStr.contains('error: [403]')) {
                  // 403 means we can't use that anymore
                  return Text(L10n.of(context).superInvitesDeleted(token));
                }
                return Text(L10n.of(context).loadingFailed(e));
              },
              loading: () => Skeletonizer(
                child: Card(
                  child: ListTile(
                    leading: ActerAvatar(
                      options: const AvatarOptions.DM(
                        AvatarInfo(uniqueId: 'nothing'),
                        size: 18,
                      ),
                    ),
                    title: const Text('some random name'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          key: redeemConfirmKey,
          onPressed: () => redeem(context, ref),
          child: Text(L10n.of(context).redeem),
        ),
      ],
    );
  }

  Widget renderInfo(BuildContext context, WidgetRef ref, SuperInviteInfo info) {
    final displayName = info.inviterDisplayNameStr();
    final userId = info.inviterUserIdStr();
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Card(
        child: ListTile(
          key: redeemInfoKey,
          title: Text(
            L10n.of(context).superInvitedBy(
              displayName != null ? '$displayName ($userId)' : userId,
            ),
          ),
          subtitle: Text(L10n.of(context).superInvitedTo(info.roomsCount())),
          leading: ActerAvatar(
            options: AvatarOptions.DM(
              AvatarInfo(
                uniqueId: userId,
                displayName: displayName,
              ),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  void redeem(BuildContext context, WidgetRef ref) async {
    final superInvites = ref.read(superInvitesProvider);

    EasyLoading.show(status: L10n.of(context).redeeming(token));
    try {
      final rooms = (await superInvites.redeem(token)).toList();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(
        L10n.of(context).addedToSpacesAndChats(rooms.length),
      );
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e, s) {
      _log.severe('Failed to redeem', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).redeemingFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

Future<bool> showReedemTokenDialog(
  BuildContext context,
  WidgetRef ref,
  String superInviteToken,
) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) =>
        _ShowRedeemTokenDialog(token: superInviteToken),
  );
}
