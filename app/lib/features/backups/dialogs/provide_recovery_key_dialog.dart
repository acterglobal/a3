import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::backups::recovery_key');

class _RecoveryKeyDialog extends ConsumerStatefulWidget {
  const _RecoveryKeyDialog();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __RecoveryKeyDialogState();
}

class __RecoveryKeyDialogState extends ConsumerState<_RecoveryKeyDialog> {
  TextEditingController recoveryKey = TextEditingController();
  bool showInput = false;
  final formKey = GlobalKey<FormState>(debugLabel: 'Recovery Key Form');

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Form(
      key: formKey,
      child: AlertDialog(
        title: Text(lang.encryptionBackupRecover),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.encryptionBackupRecoverExplainer),
              const SizedBox(height: 10),
              TextFormField(
                controller: recoveryKey,
                obscureText: !showInput,
                decoration: InputDecoration(
                  hintText: lang.encryptionBackupRecoverInputHint,
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
                            ? lang.encryptionBackupRecoverProvideKey
                            : null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.cancel),
          ),
          ActerPrimaryActionButton(
            onPressed: () => submit(context),
            child: Text(lang.encryptionBackupRecoverAction),
          ),
        ],
      ),
    );
  }

  void submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.encryptionBackupRecoverRecovering);
    try {
      final key = recoveryKey.text;
      final manager = await ref.read(backupManagerProvider.future);
      final recoveryWorked = await manager.recover(key);
      if (recoveryWorked) {
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showToast(lang.encryptionBackupRecoverRecoveringSuccess);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        _log.severe('Recovery failed');
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          lang.encryptionBackupRecoverRecoveringImportFailed,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      _log.severe('Recovery failed', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.encryptionBackupRecoverRecoveringFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

void showProviderRecoveryKeyDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) => const _RecoveryKeyDialog(),
  );
}
