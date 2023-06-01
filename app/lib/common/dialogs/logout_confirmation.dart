import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void confirmationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.logOut),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              var notifier = ref.read(authStateProvider.notifier);
              await notifier.logout(ctx);
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
