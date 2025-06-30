import 'package:acter/features/activities/providers/key_storage_urgency_provider.dart';
import 'package:acter/features/activities/widgets/activity_section_item_widget.dart';
import 'package:acter/features/activities/widgets/security_and_privacy_section/show_recovery_key_widget.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/activities/actions/key_storage_urgency_action.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StoreTheKeySecurelyWidget extends ConsumerWidget {
  const StoreTheKeySecurelyWidget({super.key});

  static bool shouldBeShown(WidgetRef ref) =>
      ref.watch(storedEncKeyProvider).valueOrNull != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final encKey = ref.watch(storedEncKeyProvider).valueOrNull;

    if (encKey == null) {
      return SizedBox.shrink();
    }

    final urgency = ref.watch(keyStorageUrgencyProvider);
    final urgencyColor = getUrgencyColor(context, urgency);

    return ActivitySectionItemWidget(
      icon: PhosphorIcons.lock(),
      iconColor: urgencyColor,
      borderColor: urgencyColor,
      title: lang.dontForgetToStoreTheKeySecurely,
      subtitle: lang.storeTheKeySecurelyDescription,
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: urgencyColor,
            side: BorderSide(color: urgencyColor),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => ShowRecoveryKeyWidget(
                    recoveryKey: encKey,
                    onKeyDestroyed: () {
                      ref.invalidate(storedEncKeyProvider);
                      ref.invalidate(storedEncKeyTimestampProvider);
                    },
                  ),
            );
          },
          child: Text(lang.showKey),
        ),
      ],
    );
  }
}
