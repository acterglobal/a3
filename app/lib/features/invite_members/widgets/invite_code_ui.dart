import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
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
              onPressed: () async {
                final token =
                    await ref.read(superInviteTokenProvider(inviteCode).future);
                if (!context.mounted) return;
                context.pushNamed(
                  Routes.actionCreateSuperInvite.name,
                  extra: token,
                );
              },
              child: Text(
                L10n.of(context).manage,
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
      final displayName =
          await ref.read(roomDisplayNameProvider(widget.roomId).future);
      String prefix =
          (displayName?.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase() ??
              '');

      final rng = Random();

      int end = 5;
      if (prefix.isEmpty) {
        end = 8;
      } else if (prefix.length > 8) {
        prefix = prefix.substring(0, 8);
        end = 3;
      } else if (prefix.length > 4) {
        end = 3;
      }

      List<String> name = [prefix];
      for (var i = 0; i < end; i++) {
        name.add(rng.nextInt(10).toString());
      }

      await newSuperInviteForRooms(
        ref,
        [widget.roomId],
        inviteCode: name.join(''),
      );
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
}
