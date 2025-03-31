import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::upgrade');

Future<bool> convertIntoActerSpace({
  required BuildContext context,
  required WidgetRef ref,
  required String spaceId,
}) async {
  final lang = L10n.of(context);
  EasyLoading.showInfo(lang.loading);
  try {
    final space = await ref.read(spaceProvider(spaceId).future);
    EasyLoading.dismiss();
    if (!context.mounted) {
      return false;
    }
    await space.setActerSpaceStates();
    EasyLoading.showToast(lang.upgradeToActerSpaceSuccess);
    return true;
  } catch (e) {
    _log.severe('Error converting into Acter space', e);
    EasyLoading.showError(lang.upgradeToActerSpaceFailed(e));
    return false;
  }
}
