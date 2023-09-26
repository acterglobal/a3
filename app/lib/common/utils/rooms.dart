import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

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
  final client = ref.read(clientProvider)!;
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
    showAdaptiveDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => DefaultDialog(
        title: Text(
          '$displayMsg failed: \n $err"',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        actions: <Widget>[
          DefaultButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            title: 'Close',
          ),
        ],
      ),
    );
  }
}
