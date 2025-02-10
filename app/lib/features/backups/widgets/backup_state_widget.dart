import 'package:acter/features/backups/dialogs/provide_recovery_key_dialog.dart';
import 'package:acter/features/backups/dialogs/show_confirm_disabling.dart';
import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::backups::widgets::backup_state');

class BackupStateWidget extends ConsumerWidget {
  final bool allowDisabling;

  const BackupStateWidget({
    super.key,
    this.allowDisabling = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(backupStateProvider)) {
      RecoveryState.enabled => allowDisabling
          ? renderCanResetAction(context, ref)
          : const SizedBox.shrink(), // nothing to see here. all good.
      RecoveryState.incomplete => renderRecoverAction(context, ref),
      RecoveryState.disabled => renderStartAction(context, ref),
      _ => renderUnknown(context, ref),
    };
  }

  Widget renderUnknown(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Skeletonizer(
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.warning),
          title: Text(lang.encryptionBackupMissing),
          subtitle: Text(lang.encryptionBackupMissingExplainer),
          trailing: OutlinedButton(
            onPressed: () {},
            child: Text(lang.loading),
          ),
        ),
      ),
    );
  }

  Widget renderCanResetAction(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.check_website_thin),
        title: Text(lang.encryptionBackupEnabled),
        subtitle: Text(lang.encryptionBackupEnabledExplainer),
        trailing: OutlinedButton.icon(
          icon: const Icon(Icons.toggle_on_outlined),
          onPressed: () => showConfirmResetDialog(context, ref),
          label: Text(lang.reset),
        ),
      ),
    );
  }

  Widget renderRecoverAction(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning),
        title: Text(lang.encryptionBackupProvideKey),
        subtitle: Text(lang.encryptionBackupProvideKeyExplainer),
        trailing: Wrap(
          children: [
            OutlinedButton(
              onPressed: () => showProviderRecoveryKeyDialog(context, ref),
              child: Text(lang.encryptionBackupProvideKeyAction),
            ),
            if (allowDisabling)
              OutlinedButton(
                onPressed: () => showConfirmResetDialog(context, ref),
                child: Text(lang.reset),
              ),
          ],
        ),
      ),
    );
  }

  Widget renderStartAction(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning),
        title: Text(lang.encryptionBackupNoBackup),
        subtitle: Text(lang.encryptionBackupNoBackupExplainer),
        trailing: OutlinedButton(
          onPressed: () => startAction(context, ref),
          child: Text(lang.encryptionBackupNoBackupAction),
        ),
      ),
    );
  }

  void startAction(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.encryptionBackupEnabling);
    String secret;
    try {
      final manager = await ref.read(backupManagerProvider.future);
      secret = await manager.enable();
    } catch (e, s) {
      _log.severe('Failed to enable backup', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.encryptionBackupEnablingFailed(e),
        duration: const Duration(seconds: 5),
      );
      return;
    }
    EasyLoading.dismiss();
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
          const LinearProgressIndicator(semanticsLabel: 'in progress'),
          ListTile(
            title: Text(currentState.toString()),
          ),
        ],
      ),
    );
  }
}
