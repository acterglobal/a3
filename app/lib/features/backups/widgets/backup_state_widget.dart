import 'package:acter/features/backups/dialogs/provide_recovery_key_dialog.dart';
import 'package:acter/features/backups/dialogs/show_confirm_disabling.dart';
import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
          title: Text(L10n.of(context).encryptionBackupMissing),
          subtitle: Text(L10n.of(context).encryptionBackupMissingExplainer),
          trailing: OutlinedButton(
            onPressed: () {},
            child: Text(L10n.of(context).loading),
          ),
        ),
      ),
    );
  }

  Widget renderCanResetAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.check_website_thin),
        title: Text(L10n.of(context).encryptionBackupEnabled),
        subtitle: Text(L10n.of(context).encryptionBackupEnabledExplainer),
        trailing: OutlinedButton.icon(
          icon: const Icon(Icons.toggle_on_outlined),
          onPressed: () => showConfirmResetDialog(context, ref),
          label: Text(L10n.of(context).reset),
        ),
      ),
    );
  }

  Widget renderRecoverAction(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning),
        title: Text(L10n.of(context).encryptionBackupProvideKey),
        subtitle: Text(L10n.of(context).encryptionBackupProvideKeyExplainer),
        trailing: Wrap(
          children: [
            OutlinedButton(
              onPressed: () => showProviderRecoveryKeyDialog(context, ref),
              child: Text(L10n.of(context).encryptionBackupProvideKeyAction),
            ),
            if (allowDisabling)
              OutlinedButton(
                onPressed: () => showConfirmResetDialog(context, ref),
                child: Text(L10n.of(context).reset),
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
        title: Text(L10n.of(context).encryptionBackupNoBackup),
        subtitle: Text(L10n.of(context).encryptionBackupNoBackupExplainer),
        trailing: OutlinedButton(
          onPressed: () => startAction(context, ref),
          child: Text(L10n.of(context).encryptionBackupNoBackupAction),
        ),
      ),
    );
  }

  void startAction(BuildContext context, WidgetRef ref) async {
    EasyLoading.show(status: L10n.of(context).encryptionBackupEnabling);
    String secret;
    try {
      final manager = ref.read(backupManagerProvider);
      secret = await manager.enable();
      EasyLoading.dismiss();
    } catch (error) {
      EasyLoading.showError(
        // ignore: use_build_context_synchronously
        L10n.of(context).encryptionBackupEnablingFailed(error),
        duration: const Duration(seconds: 5),
      );
      return;
    }
    if (context.mounted) {
      showRecoveryKeyDialog(context, ref, secret);
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
