import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final passwordFormKey = GlobalKey<FormFieldState>(
  debugLabel: 'Password Form Field',
);

class _ShowConfirmResetIdentityDialog extends ConsumerStatefulWidget {
  const _ShowConfirmResetIdentityDialog();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __ShowConfirmResetIdentityDialogState();
}

class __ShowConfirmResetIdentityDialogState
    extends ConsumerState<_ShowConfirmResetIdentityDialog> {
  final formKey = GlobalKey<FormState>(debugLabel: 'Password Form');
  bool showInput = false;
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Form(
      key: formKey,
      child: AlertDialog(
        title: Text(lang.encryptionBackupResetIdentityKeyTitle),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.encryptionBackupResetIdentityKeyExplainer),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                key: passwordFormKey,
                obscureText: !showInput,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                      showInput ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => showInput = !showInput);
                    },
                  ),
                ),
                // required field, space not allowed
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? lang.needYourPasswordToConfirm
                            : null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          ActerPrimaryActionButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.encryptionBackupResetIdentityKeyActionKeepIt),
          ),
          ActerDangerActionButton(
            onPressed: () => resetIdentity(context, ref),
            child: Text(lang.encryptionBackupResetIdentityKeyActionDestroyIt),
          ),
        ],
      ),
    );
  }

  void resetIdentity(BuildContext context, WidgetRef ref) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.encryptionBackupResetting);
    try {
      final manager = await ref.read(backupManagerProvider.future);
      final newKey = await manager.resetIdentity(passwordController.text);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(
        lang.encryptionBackupResettingSuccess,
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      ref.invalidate(storedEncKeyProvider);
      ref.read(hasProvidedKeyProvider.notifier).set(false);
      if (context.mounted) {
        Navigator.pop(context);
        showRecoveryKeyDialog(context, ref, newKey);
      }
    } catch (error) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.encryptionBackupResettingFailed(error));
    }
  }
}

void showConfirmResetIdentityDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) => const _ShowConfirmResetIdentityDialog(),
  );
}
