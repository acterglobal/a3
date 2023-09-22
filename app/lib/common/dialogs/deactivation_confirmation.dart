import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void deactivationConfirmationDialog(BuildContext context, WidgetRef ref) {
  TextEditingController passwordController = TextEditingController();
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
<<<<<<< HEAD
        title: Text('Deactivate Account',
            style: TextStyle(
                color: AppTheme.brandColorScheme.error, fontSize: 18,),),
=======
        title: Text(
          'Deactivate Account',
          style: TextStyle(
            color: AppTheme.brandColorScheme.error,
            fontSize: 32,
          ),
        ),
>>>>>>> main
        content: SingleChildScrollView(
          child: Wrap(
            children: [
              Text(
                'Careful: You are about to permanently deactivate your account ',
                style: TextStyle(
                  color: AppTheme.brandColorScheme.error,
                  fontSize: 24,
                ),
              ),
              const Text('If you proceed: \n  \n'
                  '- All your personal data will be removed from your homeserver, including display name and avatar \n'
                  '- All your sessions will be closed immediately, no other device will be able to continue their sessions \n'
                  '- You will leave all rooms, chats, spaces and DMs that you are in \n'
                  '- You will not be able to reactivate your account \n'
                  '- You will no longer be able to log in \n'
                  '- No one will be able to reuse your username (MXID), including you: this username will remain unavailable indefinitely \n'
                  '- You will be removed from the identity server, if you provided any information to be found through that (e.g. email or phone number) \n'
                  '- All local data, including any encryption keys, will be permanently deleted from this device \n'
                  '- Your old messages will still be visible to people who received them, just like emails you sent in the past. \n'
                  '\n You will not be able to reverse any of this. This is a permanent and irrevocable action.'),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  'Please provide your user password to confirm you want to deactivate your account.',
                  style: TextStyle(
                    color: AppTheme.brandColorScheme.error,
                    fontSize: 16,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
<<<<<<< HEAD
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),),
                  child: TextButton(
                            onPressed: () => ctx.pop(),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white,fontSize: 17),),
                          ),
                ),
              ),
              const SizedBox(width: 10),
           Expanded(
             child: Container(
              decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),),
               child: TextButton(
                onPressed: () async {
                  popUpDialog(
                    context: context,
                    title: Text(
                      'Deactivating your account',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    isLoader: true,
                  );
                  final sdk = await ref.read(sdkProvider.future);
                  try {
                    if (!await sdk.deactivateAndDestroyCurrentClient(
                      passwordController.text,
                    )) {
                      throw 'Deactivation and removing all local data failed';
                    }
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) {
                      return;
                    }
                    // remove pop up
                    Navigator.of(context, rootNavigator: true).pop();
                    // remove ourselves
                    Navigator.of(context, rootNavigator: true).pop();
                    context.goNamed(Routes.main.name);
                  } catch (err) {
                    // We are doing as expected, but the lints triggers.
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context, rootNavigator: true).pop();
                        
                    popUpDialog(
                      context: context,
                      title: Text(
                        'Deactivating failed: \n $err"',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      isLoader: false,
                      btnText: 'Close',
                      onPressedBtn: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    );
                  }
                },
                child: const Text('Deactivate', style: TextStyle(color: Colors.white,fontSize: 17),),
                       ),
             ),
           ),

            ],
=======
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              showAdaptiveDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => DefaultDialog(
                  title: Text(
                    'Deactivating your account',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  isLoader: true,
                ),
              );
              final sdk = await ref.read(sdkProvider.future);
              try {
                if (!await sdk.deactivateAndDestroyCurrentClient(
                  passwordController.text,
                )) {
                  throw 'Deactivation and removing all local data failed';
                }
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                // remove pop up
                Navigator.of(context, rootNavigator: true).pop();
                // remove ourselves
                Navigator.of(context, rootNavigator: true).pop();
                context.goNamed(Routes.main.name);
              } catch (err) {
                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }

                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      'Deactivating failed: \n $err"',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      DefaultButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        title: 'Close',
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Deactivate'),
>>>>>>> main
          ),
          
         
        ],
      );
    },
  );
}
