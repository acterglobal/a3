import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:go_router/go_router.dart';

Future<void> joinRoom(
  BuildContext context,
  WidgetRef ref,
  String displayMsg,
  String roomIdOrAlias,
  String? server,
) async {
  popUpDialog(
    context: context,
    title: Text(
      displayMsg,
      style: Theme.of(context).textTheme.titleSmall,
    ),
    isLoader: true,
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
    context.goNamed(
      Routes.space.name,
      pathParameters: {
        'spaceId': newSpace.getRoomIdStr(),
      },
    );
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
        '$displayMsg failed: \n $err',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: false,
      btnText: 'Close',
      onPressedBtn: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }
}
