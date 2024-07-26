import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> savePinTitle(
  BuildContext context,
  ActerPin pin,
  String newTitle,
) async {
  try {
    EasyLoading.show(status: L10n.of(context).updateName);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.title(newTitle);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}

Future<void> savePinLink(
  BuildContext context,
  ActerPin pin,
  String newLink,
) async {
  try {
    EasyLoading.show(status: L10n.of(context).updatingLinking);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.url(newLink);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}

Future<void> saveDescription(
  BuildContext context,
  String htmlBodyDescription,
  String plainDescription,
  ActerPin pin,
) async {
  try {
    EasyLoading.show(status: L10n.of(context).updatingDescription);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.contentText(plainDescription);
    updateBuilder.contentHtml(plainDescription, htmlBodyDescription);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}
