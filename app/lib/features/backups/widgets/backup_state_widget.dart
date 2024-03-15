import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BackupStateWidget extends ConsumerWidget {
  const BackupStateWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(backupStateProvider);
    if (currentState == BackupState.enabled) {
      // nothing to see here. all good.
      return const SizedBox.shrink();
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

  Widget renderRecoverAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning),
        title: const Text('Provide Recovery Key'),
        subtitle: const Text(
          'We have found an automatic encryption backup',
        ),
        trailing: OutlinedButton(
          onPressed: () {},
          child: const Text(
            'Provide Key',
          ),
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
          onPressed: () {},
          child: const Text(
            'Enable Backup',
          ),
        ),
      ),
    );
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
