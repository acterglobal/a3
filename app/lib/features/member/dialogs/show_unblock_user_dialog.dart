import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

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
            style: const TextStyle(color: Colors.white, fontSize: 24),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).thisWillAllowThemToContactYouAgain,
              ),
              TextSpan(text: L10n.of(context).continueQuestion),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(L10n.of(context).no),
          ),
          TextButton(
            onPressed: () async {
              EasyLoading.show(
                status: L10n.of(context).unblockingUserProgress,
                dismissOnTap: false,
              );
              try {
                await member.unignore();
                EasyLoading.dismiss();
                if (!context.mounted) return;

                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      L10n.of(context).unblockingUserSuccess,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // close both dialogs
                          context.pop();
                          context.pop();
                        },
                        child: Text(L10n.of(context).okay),
                      ),
                    ],
                  ),
                );
              } catch (error) {
                EasyLoading.dismiss();
                if (!context.mounted) return;
                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      L10n.of(context).unblockingUserFailed(error),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // close both dialogs
                          context.pop();
                          context.pop();
                        },
                        child: Text(L10n.of(context).okay),
                      ),
                    ],
                  ),
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
