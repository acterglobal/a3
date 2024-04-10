import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class _ShowConfirmResetDialog extends ConsumerWidget {
  const _ShowConfirmResetDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(L10n.of(context).encryptionBackupDisable),
      content: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.of(context).encryptionBackupDisableExplainer),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(L10n.of(context).encryptionBackupDisableActionKeepIt),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => disable(context, ref),
              child:
                  Text(L10n.of(context).encryptionBackupDisableActionDestroyIt),
            ),
          ],
        ),
      ],
    );
  }

  void disable(BuildContext context, WidgetRef ref) async {
    EasyLoading.show(status: L10n.of(context).encryptionBackupResetting);
    try {
      final manager = ref.read(backupManagerProvider);
      final newKey = await manager.reset();
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(
        L10n.of(context).encryptionBackupResettingSuccess,
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showRecoveryKeyDialog(context, ref, newKey);
      }
    } catch (error) {
      EasyLoading.showToast(
        // ignore: use_build_context_synchronously
        L10n.of(context).encryptionBackupResettingFailed(error),
      );
    }
  }
}

void showConfirmResetDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const _ShowConfirmResetDialog(),
  );
}
