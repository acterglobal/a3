import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ShowRecoveryDialog extends StatelessWidget {
  final String recoveryKey;
  const _ShowRecoveryDialog(this.recoveryKey);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your Backup Recover key'),
      content: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Store this Backup Recovery Key securely.',
            ),
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
                      'Recovery Key copied to clipboard',
                      toastPosition: EasyLoadingToastPosition.bottom,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text(
                'Okay',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void showRecoveryKeyDialog(
    BuildContext context, WidgetRef ref, String recoveryKey,) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) => _ShowRecoveryDialog(recoveryKey),
  );
}
