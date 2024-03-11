import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showBlockUserDialog(BuildContext context, Member member) async {
  final userId = member.userId().toString();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Block $userId'),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: 'You are about to block $userId. ',
            style: const TextStyle(color: Colors.white, fontSize: 24),
            children: const <TextSpan>[
              TextSpan(
                text:
                    "Once blocked you won't see their messages anymore and it will block their attempt to contact you directly. ",
              ),
              TextSpan(text: 'Continue?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              showAdaptiveDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => DefaultDialog(
                  title: Text(
                    'Blocking User',
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
                      'User blocked. It might takes a bit before the UI reflects this update.',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // close both dialogs
                          context.pop();
                          context.pop();
                        },
                        child: const Text('Okay'),
                      ),
                    ],
                  ),
                );
              } catch (err) {
                if (!context.mounted) {
                  return;
                }
                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      'Block user failed: \n $err"',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // close both dialogs
                          context.pop();
                          context.pop();
                        },
                        child: const Text('Okay'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
