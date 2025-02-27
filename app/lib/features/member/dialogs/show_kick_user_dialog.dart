import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::member::kick_user');

Future<void> showKickUserDialog(BuildContext context, Member member) async {
  final userId = member.userId().toString();
  final roomId = member.roomIdStr();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final lang = L10n.of(context);
      final reason = TextEditingController();
      return AlertDialog(
        title: Text(lang.kickUserTitle(userId)),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(lang.kickUserDescription(userId, roomId)),
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
              EasyLoading.show(status: lang.kickProgress);
              try {
                final maybeReason = reason.text.isNotEmpty ? reason.text : null;
                await member.kick(maybeReason);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showToast(lang.kickSuccess);
                Navigator.pop(context);
              } catch (e, s) {
                _log.severe('Failed to kick user', e, s);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showError(
                  lang.kickFailed(e),
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
