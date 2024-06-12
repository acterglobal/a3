import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> showKickUserDialog(BuildContext context, Member member) async {
  final userId = member.userId().toString();
  final roomId = member.roomIdStr();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final reason = TextEditingController();
      return AlertDialog(
        title: Text(L10n.of(context).kickUserTitle(userId)),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(L10n.of(context).kickUserDescription(userId, roomId)),
              TextFormField(
                controller: reason,
                decoration: InputDecoration(
                  hintText: L10n.of(context).reasonHint,
                  labelText: L10n.of(context).reasonLabel,
                ),
              ),
              Text(L10n.of(context).continueQuestion),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).no),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              EasyLoading.show(status: L10n.of(context).kickProgress);
              try {
                final maybeReason = reason.text.isNotEmpty ? reason.text : null;
                await member.kick(maybeReason);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showToast(L10n.of(context).kickSuccess);
                Navigator.of(context, rootNavigator: true).pop();
              } catch (error) {
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showError(
                  L10n.of(context).kickFailed(error),
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: Text(L10n.of(context).yes),
          ),
        ],
      );
    },
  );
}
