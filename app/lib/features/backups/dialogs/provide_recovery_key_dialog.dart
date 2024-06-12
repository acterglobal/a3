import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class _RecoveryKeyDialog extends ConsumerStatefulWidget {
  const _RecoveryKeyDialog();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __RecoveryKeyDialogState();
}

class __RecoveryKeyDialogState extends ConsumerState<_RecoveryKeyDialog> {
  TextEditingController recoveryKey = TextEditingController();
  bool showInput = false;
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AlertDialog(
        title: Text(L10n.of(context).encryptionBackupRecover),
        content: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(L10n.of(context).encryptionBackupRecoverExplainer),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: recoveryKey,
                obscureText: !showInput,
                decoration: InputDecoration(
                  hintText: L10n.of(context).encryptionBackupRecoverInputHint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      showInput ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showInput = !showInput;
                      });
                    },
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? L10n.of(context).encryptionBackupRecoverProvideKey
                    : null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).cancel),
          ),
          ActerPrimaryActionButton(
            onPressed: () => submit(context),
            child: Text(L10n.of(context).encryptionBackupRecoverAction),
          ),
        ],
      ),
    );
  }

  void submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    EasyLoading.show(
      status: L10n.of(context).encryptionBackupRecoverRecovering,
    );
    try {
      final key = recoveryKey.text;
      final manager = ref.read(backupManagerProvider);
      final recoveryWorked = await manager.recover(key);
      if (recoveryWorked) {
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showToast(
          L10n.of(context).encryptionBackupRecoverRecoveringSuccess,
        );
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } else {
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          L10n.of(context).encryptionBackupRecoverRecoveringImportFailed,
        );
      }
    } catch (error) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).encryptionBackupRecoverRecoveringFailed(error),
      );
    }
  }
}

void showProviderRecoveryKeyDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const _RecoveryKeyDialog(),
  );
}
