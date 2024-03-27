import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';


Future<void> showBlockUserDialog(BuildContext context, Member member) async {
  final userId = member.userId().toString();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(L10n.of(context).blockTitle(userId)),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: L10n.of(context).youAreAboutToBlock(userId),
            style: const TextStyle(color: Colors.white, fontSize: 24),
            children:  <TextSpan>[
              TextSpan(text: L10n.of(context).blockInfoText),
              TextSpan(text: L10n.of(context).continueQuestion),
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
              showAdaptiveDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => DefaultDialog(
                  title: Text(
                    L10n.of(context).blockingUserProgress,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  isLoader: true,
                ),
              );
              try {
                await member.ignore();
                if (!context.mounted) {
                  return;
                }
                context.pop();

                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      L10n.of(context).blockingUserSuccess,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // close both dialogs
                          context.pop();
                          context.pop();
                        },
                        child: Text(L10n.of(context).yes),
                      ),
                    ],
                  ),
                );
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(L10n.of(context).blockingUserFailed(error),
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
