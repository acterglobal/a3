import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class _ShowRecoveryDialog extends StatelessWidget {
  final String recoveryKey;
  const _ShowRecoveryDialog(this.recoveryKey);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).encryptionBackupRecovery),
      content: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.of(context).encryptionBackupRecoveryExplainer),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              initialValue: recoveryKey,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: recoveryKey,
                      ),
                    );
                    EasyLoading.showToast(
                      L10n.of(context)
                          .encryptionBackupRecoveryCopiedToClipboard,
                      toastPosition: EasyLoadingToastPosition.bottom,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(L10n.of(context).okay),
        ),
      ],
    );
  }
}

void showRecoveryKeyDialog(
  BuildContext context,
  WidgetRef ref,
  String recoveryKey,
) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) => _ShowRecoveryDialog(recoveryKey),
  );
}
