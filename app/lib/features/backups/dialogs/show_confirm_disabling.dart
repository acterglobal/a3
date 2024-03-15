import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ShowConfirmDisablingDialog extends ConsumerWidget {
  const _ShowConfirmDisablingDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Disable your Key Backup?'),
      content: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Disabling the key backup will destroy it locally and on your homeserver. This can't be undone. Are you sure you want to continue? ",
            ),
            SizedBox(
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
              child: const Text(
                'No, keep it',
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => disable(context, ref),
              child: const Text(
                'Yes, destroy it',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void disable(BuildContext context, WidgetRef ref) async {
    EasyLoading.show(status: 'Disabling Backup');
    try {
      final manager = ref.read(backupManagerProvider);
      final disablingWorked = await manager.disable();
      if (disablingWorked) {
        EasyLoading.showToast('Disabling successful');
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } else {
        EasyLoading.showToast('Disabling failed');
      }
    } catch (e) {
      EasyLoading.showToast('Failed to disable: $e');
    }
  }
}

void showConfirmDisablingDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) => const _ShowConfirmDisablingDialog(),
  );
}
