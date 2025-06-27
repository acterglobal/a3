import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteActions {
  static Future<void> handleInvite({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required Room room,
    Task? task,
  }) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.invitingLoading(userId), dismissOnTap: false);
    try {
      if (task != null) {
        final invitationsManager = await task.invitations();
        await invitationsManager.invite(userId);
      } else {
        await room.inviteUser(userId);
      }
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(lang.invitingError(e, userId));
    }
  }

  static Future<void> handleCancelInvite({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required Room room,
  }) async {
    final lang = L10n.of(context);
    EasyLoading.show(
      status: lang.cancelInviteLoading(userId),
      dismissOnTap: false,
    );
    try {
      final member = ref.read(memberProvider((userId: userId, roomId: room.roomIdStr()))).valueOrNull;
      
      if (member != null) {
        await member.kick('Cancel Invite');
      }
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(lang.cancelInviteError(e, userId));
    }
  }
}
