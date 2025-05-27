import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ShowConfirmRotateDialog extends ConsumerWidget {
  const _ShowConfirmRotateDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.encryptionBackupRotateKeyTitle),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.encryptionBackupRotateKeyExplainer),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        ActerPrimaryActionButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.encryptionBackupRotateKeyActionKeepIt),
        ),
        ActerDangerActionButton(
          onPressed: () => rotate(context, ref),
          child: Text(lang.encryptionBackupRotateKeyActionDestroyIt),
        ),
      ],
    );
  }

  void rotate(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.encryptionBackupResetting);
    try {
      final manager = await ref.read(backupManagerProvider.future);
      final newKey = await manager.resetKey();
      ref.read(hasProvidedKeyProvider.notifier).set(false);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(
        lang.encryptionBackupResettingSuccess,
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      if (context.mounted) {
        Navigator.pop(context);
        showRecoveryKeyDialog(context, ref, newKey);
      }
      ref.invalidate(storedEncKeyProvider);
    } catch (error) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.encryptionBackupResettingFailed(error));
    }
  }
}

void showConfirmRotateDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) => const _ShowConfirmRotateDialog(),
  );
}
