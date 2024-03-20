import 'package:acter/features/backups/dialogs/provide_recovery_key_dialog.dart';
import 'package:acter/features/backups/dialogs/show_confirm_disabling.dart';
import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BackupStateWidget extends ConsumerWidget {
  final bool allowDisabling;
  const BackupStateWidget({super.key, this.allowDisabling = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(backupStateProvider)) {
      case RecoveryState.enabled:
        if (allowDisabling) {
          return renderCanResetAction(context, ref);
        } else {
          // nothing to see here. all good.
          return const SizedBox.shrink();
        }
      case RecoveryState.incomplete:
        return renderRecoverAction(context, ref);
      case RecoveryState.disabled:
        return renderStartAction(context, ref);
      default:
        return renderUnknown(context, ref);
    }
  }

  Widget renderUnknown(BuildContext context, WidgetRef ref) {
    return Skeletonizer(
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.warning),
          title: const Text('Encryption backups missing'),
          subtitle: const Text(
            'We recommend to use automatic encryption key backups',
          ),
          trailing:
              OutlinedButton(onPressed: () {}, child: const Text('loading')),
        ),
      ),
    );
  }

  Widget renderCanResetAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.check_website_thin),
        title: const Text('Backup enabled'),
        subtitle: const Text(
          'Your keys are stored in an encrypted backup on your home server',
        ),
        trailing: OutlinedButton.icon(
          icon: const Icon(Icons.toggle_on_outlined),
          onPressed: () => showConfirmResetDialog(context, ref),
          label: const Text(
            'reset',
          ),
        ),
      ),
    );
  }

  Widget renderRecoverAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning),
        title: const Text('Provide Recovery Key'),
        subtitle: const Text(
          'We have found an automatic encryption backup',
        ),
        trailing: Wrap(
          children: [
            OutlinedButton(
              onPressed: () => showProviderRecoveryKeyDialog(context, ref),
              child: const Text(
                'Provide Key',
              ),
            ),
            if (allowDisabling)
              OutlinedButton(
                onPressed: () => showConfirmResetDialog(context, ref),
                child: const Text(
                  'reset',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget renderStartAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning),
        title: const Text('No encryption backup found'),
        subtitle: const Text(
          'If you lose access to your account, conversations might become unrecoverable. We recommend enabling automatic encryption backups.',
        ),
        trailing: OutlinedButton(
          onPressed: () => startAction(context, ref),
          child: const Text(
            'Enable Backup',
          ),
        ),
      ),
    );
  }

  void startAction(BuildContext context, WidgetRef ref) async {
    EasyLoading.show(status: 'enabling backup');
    String secret;
    try {
      final manager = ref.read(backupManagerProvider);
      secret = await manager.enable();
      print('Secret: $secret');
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.showError(
        'enabling backup failed: $e',
        duration: const Duration(seconds: 5),
      );
      return;
    }
    if (context.mounted) {
      showRecoveryKeyDialog(context, ref, secret);
    } else {
      print('Dialog closed. Your backup encryption recovery key is: $secret');
    }
  }

  Widget renderInProgress(
    BuildContext context,
    WidgetRef ref,
    RecoveryState currentState,
  ) {
    return Card(
      child: Column(
        children: [
          const LinearProgressIndicator(
            semanticsLabel: 'in progress',
          ),
          ListTile(title: Text('$currentState')),
        ],
      ),
    );
  }
}
