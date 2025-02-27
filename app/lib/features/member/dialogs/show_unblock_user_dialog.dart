import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::member::unblock_user');

Future<void> showUnblockUserDialog(BuildContext context, Member member) async {
  final userId = member.userId().toString();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final lang = L10n.of(context);
      return AlertDialog(
        title: Text(lang.unblockTitle(userId)),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: lang.youAreAboutToUnblock(userId),
            style: Theme.of(context).textTheme.headlineMedium,
            children: <TextSpan>[
              TextSpan(text: lang.thisWillAllowThemToContactYouAgain),
              TextSpan(text: lang.continueQuestion),
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
              EasyLoading.show(status: lang.unblockingUserProgress);
              try {
                await member.unignore();
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showToast(lang.unblockingUserSuccess);
              } catch (e, s) {
                _log.severe('Failed to unblock user', e, s);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showError(
                  lang.unblockingUserFailed(e),
                  duration: const Duration(seconds: 3),
                );
              }
              Navigator.pop(context);
            },
            child: Text(lang.yes),
          ),
        ],
      );
    },
  );
}
