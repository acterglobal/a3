import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void logoutConfirmationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.logOut),
        content: RichText(
          textAlign: TextAlign.left,
          text: const TextSpan(
            text: 'Attention',
            style: TextStyle(color: Colors.white, fontSize: 32),
            children: <TextSpan>[
              TextSpan(
                text:
                    'Logging out removes the local data, including encryption keys. If this is your last signed-in device you might no be able to decrypt any previous content.',
              ),
              TextSpan(text: 'Are you sure you want to log out?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout(ctx);
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
