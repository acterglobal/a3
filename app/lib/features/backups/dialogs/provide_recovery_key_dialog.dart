import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Recover Encryption Backup'),
        content: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Provider you recovery key to decrypt the encryption backup',
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: recoveryKey,
                obscureText: !showInput,
                decoration: InputDecoration(
                  hintText: 'Recovery key',
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please provide the key' : null,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Row(
            children: [
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: const Text(
                  'Cancel',
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => submit(context),
                child: const Text(
                  'Recover',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    EasyLoading.show(status: 'Trying to recover');
    try {
      final key = recoveryKey.text;
      final manager = ref.read(backupManagerProvider);
      final recoveryWorked = await manager.recover(key);
      if (recoveryWorked) {
        EasyLoading.showToast('Recovery successful');
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } else {
        EasyLoading.showToast('Import failed');
      }
    } catch (e) {
      EasyLoading.showToast('Failed to recover: $e');
    }
  }
}

void showProviderRecoveryKeyDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const _RecoveryKeyDialog(),
  );
}
