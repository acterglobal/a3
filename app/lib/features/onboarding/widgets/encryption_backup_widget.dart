import 'dart:io';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/app_install_check_provider.dart';
import 'package:acter/features/share/action/shareTo.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PasswordManagerBackupWidget extends ConsumerWidget {
  final String encryptionKey;

  const PasswordManagerBackupWidget({
    super.key,
    required this.encryptionKey,
  });

  Future<void> _buildShareContent(L10n lang) async {
    await Clipboard.setData(ClipboardData(text: encryptionKey));
    EasyLoading.showSuccess(lang.keyCopied);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    Widget? addButtonIfInstalled(
      bool isInstalled,
      IconData icon,
      Future<void> Function() onTap,
    ) {
      if (isInstalled) {
        return _buildActionButton(
          icon: icon,
          onTap: () async {
            await _buildShareContent(lang);
            if (!context.mounted) return;
            await Future.delayed(const Duration(seconds: 2));
            await onTap();
          },
          context: context,
        );
      }
      return null;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: [
        // Copy button
        _buildActionButton(
          icon: Icons.copy,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: encryptionKey));
            if (context.mounted) {
              EasyLoading.showToast(lang.keyCopied);
            }
          },
          context: context,
        ),
        // Share button
        _buildActionButton(
          icon: PhosphorIcons.share(),
          onTap: () async {
            await Share.share(encryptionKey);
          },
          context: context,
        ),
        // 1Password (no platform restriction)
        addButtonIfInstalled(
          ref.watch(isAppInstalledProvider(ExternalApps.onePassword)).valueOrNull == true,
          Icons.security,
          () => shareToOnePassword(context: context),
        ),
        // Bitwarden (no platform restriction)
        addButtonIfInstalled(
          ref.watch(isAppInstalledProvider(ExternalApps.bitwarden)).valueOrNull == true,
          Icons.vpn_key,
          () => shareToBitwarden(context: context),
        ),
        // Keeper (iOS only)
        addButtonIfInstalled(
          Platform.isIOS &&
              ref.watch(isAppInstalledProvider(ExternalApps.keeper)).valueOrNull == true,
          Icons.lock_person,
          () => shareToKeeper(context: context),
        ),
        // LastPass (iOS only)
        addButtonIfInstalled(
          Platform.isIOS &&
              ref.watch(isAppInstalledProvider(ExternalApps.lastPass)).valueOrNull == true,
          Icons.password,
          () => shareToLastPass(context: context),
        ),
        // Enpass (iOS only)
        addButtonIfInstalled(
          Platform.isIOS &&
              ref.watch(isAppInstalledProvider(ExternalApps.enpass)).valueOrNull == true,
          PhosphorIcons.vault(),
          () => shareToEnpass(context: context),
        ),
        // ProtonPass (iOS only)
        addButtonIfInstalled(
          Platform.isIOS &&
              ref.watch(isAppInstalledProvider(ExternalApps.protonPass)).valueOrNull == true,
          Icons.shield,
          () => shareToProtonPass(context: context),
        ),
      ].whereType<Widget>().toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Icon(icon),
      ),
    );
  }
}

