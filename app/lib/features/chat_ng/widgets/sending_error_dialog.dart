import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState;
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_options.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_container.dart';

class SendingErrorDialog extends StatelessWidget {
  static const retryBtn = Key('sending-error-dialog-retry-btn');

  final EventSendState state;

  const SendingErrorDialog({super.key, required this.state});

  static Future show({
    required BuildContext context,
    required EventSendState state,
  }) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, __) => SendingErrorDialog(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = L10n.of(context);

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      content: QuickAlertContainer(
        options: QuickAlertOptions(
          title: lang.chatSendingFailed,
          text: state.error() ?? 'Error sending message',
          type: QuickAlertType.error,
          showCancelBtn: true,
          showConfirmBtn: true,
          confirmBtnText: lang.abortSending,
          cancelBtnText: lang.close,
          confirmBtnColor: theme.primaryColor,
          onConfirmBtnTap: () => state.abort(),
          borderRadius: 15.0,
        ),
      ),
    );
  }
}
