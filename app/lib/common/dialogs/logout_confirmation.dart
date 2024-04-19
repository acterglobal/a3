import 'package:acter/common/models/keys.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/default_action_button.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void logoutConfirmationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Atlas.warning,
              color: Colors.red,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(L10n.of(context).logOut),
          ],
        ),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: L10n.of(context).logOutConformationDescription1,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).logOutConformationDescription2,
              ),
              TextSpan(
                text: L10n.of(context).logOutConformationDescription3,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          ActerDefaultActionButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              L10n.of(context).no,
              key: LogoutDialogKeys.cancel,
            ),
          ),
          ActerDangerActionButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout(ctx);
            },
            child: Text(
              L10n.of(context).yes,
              key: LogoutDialogKeys.confirm,
            ),
          ),
        ],
      );
    },
  );
}
