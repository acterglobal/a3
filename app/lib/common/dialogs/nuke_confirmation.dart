import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/auth/providers/auth_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void nukeConfirmationDialog(BuildContext context, WidgetRef ref) {
  showAdaptiveDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Atlas.bomb_bold, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 10),
            const Text('Nuke all local data'),
          ],
        ),
        content: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            text: 'Attention: ',
            style: Theme.of(context).textTheme.bodyMedium,
            children: const <TextSpan>[
              TextSpan(
                text:
                    'Nuking removes all local data, including encryption keys. If this is your last signed-in device you might no be able to decrypt any previous content.',
              ),
              TextSpan(text: 'Are you sure you want to nuke?'),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ActerDangerActionButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).nuke();

              if (context.mounted) {
                context.goNamed(Routes.main.name);
              }
            },
            child: const Text('Yihaaaa'),
          ),
        ],
      );
    },
  );
}
