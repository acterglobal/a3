import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::invite::generate_invitecode_externally_actions');

Future<String> generateNewInviteCode(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    final lang = L10n.of(context);
    try {
      EasyLoading.show(status: lang.generateInviteCode);
      final displayName = await ref.read(
        roomDisplayNameProvider(roomId).future,
      );
      final inviteCode = generateInviteCodeName(displayName);

      await newSuperInviteForRooms(ref, [
        roomId,
      ], inviteCode: inviteCode);
      ref.invalidate(superInvitesProvider);
      EasyLoading.dismiss();
      return inviteCode;
    } catch (e, s) {
      _log.severe('Invite code activation failed', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return '';
      }
      EasyLoading.showError(
        lang.activateInviteCodeFailed(e),
        duration: const Duration(seconds: 3),
      );
      return '';
    }
  }

Future<void> copyInviteCodeToClipboard(String inviteCode, BuildContext context) async {
  await Clipboard.setData(ClipboardData(text: inviteCode));
  if (!context.mounted) return;
  EasyLoading.showToast(L10n.of(context).inviteCopiedToClipboard);
}

Future<String> getInviteCode(BuildContext context, List<SuperInviteToken> inviteCodeList, WidgetRef ref, String roomId) async {
    if(inviteCodeList.isEmpty) {
      return await generateNewInviteCode(context, ref, roomId);
    } else {
      final token = inviteCodeList.firstWhere(
        (t) => t.rooms().isNotEmpty, // find the first that is only our room
        orElse: () => inviteCodeList.first, // or otherwise pick the first available
      );
      return token.token();
    }
  }