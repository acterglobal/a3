import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> joinRoom(
  BuildContext context,
  WidgetRef ref,
  String displayMsg,
  String roomIdOrAlias,
  String? server,
  Function(String) forward,
) async {
  EasyLoading.show(status: displayMsg, dismissOnTap: false);
  final client = ref.read(alwaysClientProvider);
  try {
    final newSpace = await client.joinSpace(roomIdOrAlias, server);
    EasyLoading.dismiss();
    if (!context.mounted) return;
    forward(newSpace.getRoomIdStr());
  } catch (err) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(
      '$displayMsg ${L10n.of(context).failed}: \n $err"',
      duration: const Duration(seconds: 3),
    );
  }
}
