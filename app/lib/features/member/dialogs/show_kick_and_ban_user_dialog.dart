import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::member::kick_and_ban');

Future<void> showKickAndBanUserDialog(
  BuildContext context,
  Member member,
) async {
  final userId = member.userId().toString();
  final roomId = member.roomIdStr();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final lang = L10n.of(context);
      final reason = TextEditingController();
      return AlertDialog(
        title: Text(lang.kickAndBanUserTitle(userId)),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(lang.kickAndBanUserDescription(userId, roomId)),
              Text(lang.theyWontBeAbleToJoinAgain),
              TextFormField(
                controller: reason,
                decoration: InputDecoration(
                  hintText: lang.reasonHint,
                  labelText: lang.reasonLabel,
                ),
              ),
              Text(lang.continueQuestion),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.no),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              EasyLoading.show(status: lang.kickAndBanProgress);
              try {
                final maybeReason = reason.text.isNotEmpty ? reason.text : null;
                await member.kick(maybeReason);
                await member.ban(maybeReason);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showToast(lang.kickAndBanSuccess);
                Navigator.pop(context);
              } catch (e, s) {
                _log.severe('Failed to kick and ban user', e, s);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showError(
                  lang.kickAndBanFailed(e),
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: Text(lang.yes),
          ),
        ],
      );
    },
  );
}
