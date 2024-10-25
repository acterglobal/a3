import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::submit::comment');

Future<void> submitComment(
  BuildContext context,
  String plainDescription,
  String htmlBodyDescription,
  CommentsManager manager,
) async {
  final lang = L10n.of(context);
  if (plainDescription.isEmpty) {
    EasyLoading.showToast(lang.youNeedToEnterAComment);
    return;
  }
  EasyLoading.show(status: lang.submittingComment);
  try {
    final draft = manager.commentDraft();
    draft.contentFormatted(plainDescription, htmlBodyDescription);
    await draft.send();
    FocusManager.instance.primaryFocus?.unfocus();
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.commentSubmitted);
  } catch (e, s) {
    _log.severe('Failed to submit comment', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.errorSubmittingComment(e),
      duration: const Duration(seconds: 3),
    );
  }
}
