import 'dart:async';

import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::update_actions');

Future<void> updatePinTitle(
  BuildContext context,
  WidgetRef ref,
  ActerPin pin,
  String newTitle,
) async {
  final lang = L10n.of(context);
  try {
    EasyLoading.show(status: lang.updateName);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.title(newTitle);
    await updateBuilder.send();

    await autosubscribe(
      ref: ref,
      objectId: pin.eventIdStr(),
      lang: lang,
    );
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to rename pin', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updateNameFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> updatePinLink(
  BuildContext context,
  ActerPin pin,
  String newLink,
) async {
  final lang = L10n.of(context);
  try {
    EasyLoading.show(status: lang.updatingLinking);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.url(newLink);
    await updateBuilder.send();
    EasyLoading.dismiss();
  } catch (e, s) {
    _log.severe('Failed to change url of pin', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updateNameFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> updatePinDescription(
  BuildContext context,
  WidgetRef ref,
  String htmlBodyDescription,
  String plainDescription,
  ActerPin pin,
) async {
  final lang = L10n.of(context);
  try {
    EasyLoading.show(status: lang.updatingDescription);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.contentText(plainDescription);
    updateBuilder.contentHtml(plainDescription, htmlBodyDescription);
    await updateBuilder.send();

    await autosubscribe(
      ref: ref,
      objectId: pin.eventIdStr(),
      lang: lang,
    );
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to change description of pin', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updateDescriptionFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> updatePinIcon(
  BuildContext context,
  WidgetRef ref,
  ActerPin pin,
  Color color,
  ActerIcon acterIcon,
) async {
  final lang = L10n.of(context);
  try {
    EasyLoading.show(status: lang.updatingIcon);
    // Pin IconData
    final sdk = await ref.watch(sdkProvider.future);
    final displayBuilder = sdk.api.newDisplayBuilder();
    displayBuilder.color(color.toInt());
    displayBuilder.icon('acter-icon', acterIcon.name);

    final updateBuilder = pin.updateBuilder();
    updateBuilder.display(displayBuilder.build());

    await updateBuilder.send();
    EasyLoading.dismiss();

    //TODO : this only fixes the case where we do the update. if the change comes from outside - another user - this will not trigger.
    ref.invalidate(pinProvider);
    ref.invalidate(pinListProvider);
  } catch (e, s) {
    _log.severe('Failed to change icon of pin', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updateNameFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}
