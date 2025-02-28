import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ShowRecoveryDialog extends StatelessWidget {
  final String recoveryKey;

  const _ShowRecoveryDialog(this.recoveryKey);

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.encryptionBackupRecovery),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.encryptionBackupRecoveryExplainer),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: recoveryKey,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: recoveryKey));
                    EasyLoading.showToast(
                      lang.encryptionBackupRecoveryCopiedToClipboard,
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
          onPressed: () => Navigator.pop(context),
          child: Text(lang.okay),
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
    builder: (BuildContext context) => _ShowRecoveryDialog(recoveryKey),
  );
}
