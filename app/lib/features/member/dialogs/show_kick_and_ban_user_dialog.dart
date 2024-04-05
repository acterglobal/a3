import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> showKickAndBanUserDialog(
  BuildContext context,
  Member member,
) async {
  final userId = member.userId().toString();
  final roomId = member.roomIdStr();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final reason = TextEditingController();
      return AlertDialog(
        title: Text(L10n.of(context).kickAndBanUserTitle(userId)),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(L10n.of(context).kickAndBanUserDescription(userId, roomId)),
              Text(L10n.of(context).theyWontBeAbleToJoinAgain),
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
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).no),
          ),
          TextButton(
            onPressed: () async {
              EasyLoading.show(
                status: L10n.of(context).kickAndBanProgress,
                dismissOnTap: false,
              );
              try {
                final maybeReason = reason.text.isNotEmpty ? reason.text : null;
                await member.kick(maybeReason);
                await member.ban(maybeReason);
                EasyLoading.dismiss();
                if (!context.mounted) return;
                EasyLoading.showToast(L10n.of(context).kickAndBanSuccess);
                Navigator.of(context, rootNavigator: true).pop();
              } catch (error) {
                EasyLoading.dismiss();
                if (!context.mounted) return;
                EasyLoading.showError(
                  L10n.of(context).kickAndBanFailed(error),
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
