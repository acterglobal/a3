import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> showUnblockUserDialog(BuildContext context, Member member) async {
  final userId = member.userId().toString();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(L10n.of(context).unblockTitle(userId)),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: L10n.of(context).youAreAboutToUnblock(userId),
            style: Theme.of(context).textTheme.headlineMedium,
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).thisWillAllowThemToContactYouAgain,
              ),
              TextSpan(text: L10n.of(context).continueQuestion),
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
              EasyLoading.show(status: L10n.of(context).unblockingUserProgress);
              try {
                await member.unignore();
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showToast(L10n.of(context).unblockingUserSuccess);
              } catch (error) {
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showError(
                  L10n.of(context).unblockingUserFailed(error),
                  duration: const Duration(seconds: 3),
                );
              }
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(L10n.of(context).yes),
          ),
        ],
      );
    },
  );
}
