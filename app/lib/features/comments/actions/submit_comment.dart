import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::submit::comment');

Future<bool> submitComment(
  L10n lang,
  String plainDescription,
  String htmlBodyDescription,
  CommentsManager manager,
) async {
  final trimmedPlainText = plainDescription.trim();
  if (trimmedPlainText.isEmpty) {
    EasyLoading.showToast(lang.youNeedToEnterAComment);
    return false;
  }
  EasyLoading.show(status: lang.submittingComment);
  try {
    final draft = manager.commentDraft();
    draft.contentFormatted(trimmedPlainText, htmlBodyDescription);
    await draft.send();
    FocusManager.instance.primaryFocus?.unfocus();
    EasyLoading.showToast(lang.commentSubmitted);
    return true;
  } catch (e, s) {
    _log.severe('Failed to submit comment', e, s);
    EasyLoading.showError(
      lang.errorSubmittingComment(e),
      duration: const Duration(seconds: 3),
    );
    return false;
  }
}
