import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/activities/widgets/activity_section_item_widget.dart';
import 'package:acter/features/backups/dialogs/provide_recovery_key_dialog.dart';
import 'package:acter/features/backups/dialogs/show_confirm_reset_identity.dart';
import 'package:acter/features/backups/dialogs/show_confirm_rotate.dart';
import 'package:acter/features/backups/dialogs/show_recovery_key.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::backups::widgets::backup_state');

class BackupStateWidget extends ConsumerWidget {
  final bool allowDisabling;

  const BackupStateWidget({super.key, this.allowDisabling = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(backupStateProvider)) {
      RecoveryState.enabled =>
        allowDisabling
            ? renderCanResetAction(context, ref)
            : const SizedBox.shrink(), // nothing to see here. all good.
      RecoveryState.incomplete =>
        (ref.watch(hasProvidedKeyProvider).valueOrNull == true)
            ? renderRecoverActionFailed(
              context,
              ref,
            ) // we tried and now have to alert the user about this failing
            : renderRecoverActionSimple(context, ref),
      RecoveryState.disabled => renderStartAction(context, ref),
      _ => renderUnknown(context, ref),
    };
  }

  Widget renderUnknown(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Skeletonizer(
      child: ActivitySectionItemWidget(
        icon: Icons.warning_amber_rounded,
        iconColor: warningColor,
        title: lang.encryptionBackupMissing,
        subtitle: lang.encryptionBackupMissingExplainer,
        actions: [OutlinedButton(onPressed: null, child: Text(lang.loading))],
      ),
    );
  }

  Widget renderCanResetAction(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return ActivitySectionItemWidget(
      icon: Atlas.check_website_thin,
      iconColor: Theme.of(context).colorScheme.primary,
      title: lang.encryptionBackupEnabled,
      subtitle: lang.encryptionBackupEnabledExplainer,
      actions: [
        rotateKeyAction(context, ref),
        const SizedBox(width: 8),
        resetIdentityAction(context, ref),
      ],
    );
  }

  Widget renderRecoverActionFailed(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return ActivitySectionItemWidget(
      icon: Icons.warning_amber_rounded,
      iconColor: warningColor,
      title: lang.encryptionBackupProvideKeyFailed,
      subtitle: lang.encryptionBackupProvideKeyFailedExplainer,
      trailing: InkWell(
        onTap:
            () => openLink(
              ref: ref,
              target: 'https://acter.global/guide/understanding-key-backups-2/',
              lang: L10n.of(context),
            ),
        child: const Icon(Icons.info),
      ),
      actions: [
        provideKeyAction(context, ref),
        const SizedBox(width: 8),
        resetIdentityAction(context, ref),
      ],
    );
  }

  Widget renderRecoverActionSimple(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return ActivitySectionItemWidget(
      icon: Icons.warning_amber_rounded,
      iconColor: warningColor,
      title: lang.encryptionBackupProvideKey,
      subtitle: lang.encryptionBackupProvideKeyExplainer,
      actions: [
        provideKeyAction(context, ref),
        if (allowDisabling) ...[
          const SizedBox(width: 8),
          resetIdentityAction(context, ref),
        ],
      ],
    );
  }

  Widget renderStartAction(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return ActivitySectionItemWidget(
      icon: Icons.warning_amber_rounded,
      iconColor: warningColor,
      title: lang.encryptionBackupNoBackup,
      subtitle: lang.encryptionBackupNoBackupExplainer,
      actions: [
        OutlinedButton(
          onPressed: () => startAction(context, ref),
          child: Text(lang.encryptionBackupNoBackupAction),
        ),
      ],
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
          ListTile(title: Text(currentState.toString())),
        ],
      ),
    );
  }

  // Action Buttons

  Widget rotateKeyAction(BuildContext context, WidgetRef ref) => OutlinedButton(
    onPressed: () => showConfirmRotateDialog(context, ref),
    child: Text(L10n.of(context).encryptionBackupRotateKey),
  );

  Widget resetIdentityAction(BuildContext context, WidgetRef ref) =>
      OutlinedButton(
        onPressed: () => showConfirmResetIdentityDialog(context, ref),
        child: Text(L10n.of(context).encryptionBackupResetIdentity),
      );

  Widget provideKeyAction(BuildContext context, WidgetRef ref) =>
      OutlinedButton(
        onPressed: () => showProviderRecoveryKeyDialog(context, ref),
        child: Text(L10n.of(context).encryptionBackupProvideKeyAction),
      );
}
