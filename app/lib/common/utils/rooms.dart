import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> joinRoom(
  BuildContext context,
  WidgetRef ref,
  String displayMsg,
  String roomIdOrAlias,
  String? server,
  Function(String) forward,
) async {
  showAdaptiveDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => DefaultDialog(
      title: Text(
        displayMsg,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    ),
  );
  final client = ref.read(alwaysClientProvider);
  try {
    final newSpace = await client.joinSpace(
      roomIdOrAlias,
      server,
    );
    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    forward(newSpace.getRoomIdStr());
  } catch (err) {
    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    showAdaptiveDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => DefaultDialog(
        title: Text(
          '$displayMsg ${L10n.of(context).failed}: \n $err"',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).close),
          ),
        ],
      ),
    );
  }
}
