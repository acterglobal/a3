import 'package:acter/common/models/keys.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/features/auth/providers/auth_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void logoutConfirmationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final lang = L10n.of(context);
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Atlas.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 10),
            Text(lang.logOut),
          ],
        ),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: lang.logOutConformationDescription1,
            style: Theme.of(context).textTheme.bodyLarge,
            children: <TextSpan>[
              TextSpan(text: lang.logOutConformationDescription2),
              TextSpan(text: lang.logOutConformationDescription3),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.no,
              key: LogoutDialogKeys.cancel,
            ),
          ),
          ActerDangerActionButton(
            onPressed: () async {
              final notifier = ref.read(authStateProvider.notifier);
              await notifier.logout(context);
            },
            child: Text(
              lang.yes,
              key: LogoutDialogKeys.confirm,
            ),
          ),
        ],
      );
    },
  );
}
