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
    final currentState = ref.watch(backupStateProvider);
    if (currentState == BackupState.enabled) {
      if (allowDisabling) {
        return renderCanDisableAction(context, ref);
      } else {
        // nothing to see here. all good.
        return const SizedBox.shrink();
      }
    } else if (currentState == BackupState.unknown) {
      return renderUnknown(context, ref);
    }
    return renderInProgress(context, ref, currentState);
  }

  Widget renderUnknown(BuildContext context, WidgetRef ref) {
    final existsOnServerLoader = ref.watch(backupExistsOnServerProvider);
    return existsOnServerLoader.when(
      data: (existsOnServer) => existsOnServer
          ? renderRecoverAction(context, ref)
          : renderStartAction(context, ref),
      error: (e, s) => Card(
        child: ListTile(
          leading: const Icon(Icons.warning),
          title: const Text('Error checking backup state'),
          subtitle: Text('$e'),
        ),
      ),
      loading: () => Skeletonizer(
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
      ),
    );
  }

  Widget renderCanDisableAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.check_website_thin),
        title: const Text('Backup enabled'),
        subtitle: const Text(
          'Your keys are stored in an encrypted backup on your home server',
        ),
        trailing: OutlinedButton.icon(
          icon: const Icon(Icons.toggle_on_outlined),
          onPressed: () => showConfirmDisablingDialog(context, ref),
          label: const Text(
            'enabled',
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
                onPressed: () => showConfirmDisablingDialog(context, ref),
                child: const Text(
                  'disable',
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
      secret = await manager.createNewSecretStore();
      print('Secret: $secret');
      await manager.create();
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.show(status: 'enabling backup failed: $e');
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
    BackupState currentState,
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
