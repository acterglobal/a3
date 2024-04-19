import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: Text(L10n.of(context).encryptionBackupKeyBackup),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Text(L10n.of(context).encryptionBackupKeyBackupExplainer),
            const BackupStateWidget(allowDisabling: true),
          ],
        ),
      ),
    );
  }
}
