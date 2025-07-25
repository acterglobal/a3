import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::submit::comment');

Future<String?> submitComment(
  L10n lang,
  String plainDescription,
  String htmlBodyDescription,
  CommentsManager manager,
) async {
  final trimmedPlainText = plainDescription.trim();
  if (trimmedPlainText.isEmpty) {
    EasyLoading.showToast(lang.youNeedToEnterAComment);
    return null;
  }
  EasyLoading.show(status: lang.submittingComment);
  try {
    final draft =
        manager.commentDraft()
          ..contentFormatted(trimmedPlainText, htmlBodyDescription);
    final id = await draft.send();
    FocusManager.instance.primaryFocus?.unfocus();
    EasyLoading.showToast(lang.commentSubmitted);
    return id.toString();
  } catch (e, s) {
    _log.severe('Failed to submit comment', e, s);
    EasyLoading.showError(
      lang.errorSubmittingComment(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
