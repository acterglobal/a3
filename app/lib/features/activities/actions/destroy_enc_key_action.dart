import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void destroyEncKey(BuildContext context, WidgetRef ref, [VoidCallback? callNextPage]) async {
    final lang = L10n.of(context);
    try {
      final manager = await ref.read(backupManagerProvider.future);
      final destroyed = await manager.destroyStoredEncKey();
      if (destroyed) {
        if (!context.mounted) return;
        Navigator.pop(context);
        callNextPage != null ? callNextPage() : null;
      } else {
        if (!context.mounted) return;
        EasyLoading.showError(
          lang.keyDestroyedFailed,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      EasyLoading.showError(
        lang.keyDestroyedFailed,
        duration: const Duration(seconds: 3),
      );
    }
  }