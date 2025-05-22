import 'dart:io';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/app_install_check_provider.dart';
import 'package:acter/features/encryption_backup_feature/actions/external_storing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PasswordManagerBackupWidget extends ConsumerWidget {
  final String encryptionKey;
  final VoidCallback onButtonPressed;

  const PasswordManagerBackupWidget({
    super.key,
    required this.encryptionKey,
    required this.onButtonPressed,
  });

  Future<void> _buildShareContent(L10n lang) async {
    await Clipboard.setData(ClipboardData(text: encryptionKey));
    EasyLoading.showSuccess(lang.keyCopied);
    onButtonPressed.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    bool isAppInstalled(WidgetRef ref, ExternalApps app) {
      return ref.watch(isAppInstalledProvider(app)).valueOrNull == true;
    } 

    final isOnePasswordInstalled = isAppInstalled(ref, ExternalApps.onePassword);
    final isBitwardenInstalled = isAppInstalled(ref, ExternalApps.bitwarden);
    final isKeeperInstalled = isAppInstalled(ref, ExternalApps.keeper);
    final isLastPassInstalled = isAppInstalled(ref, ExternalApps.lastPass);
    final isEnpassInstalled = isAppInstalled(ref, ExternalApps.enpass);
    final isProtonPassInstalled = isAppInstalled(ref, ExternalApps.protonPass);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: [ 
        // Copy button
        _buildWithFirsCopyButton(
          context: context,
          icon: Icons.copy,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: encryptionKey));
            if (context.mounted) {
              EasyLoading.showToast(lang.keyCopied);
            }
          },
          lang: lang,
        ),
        // Share button
        _buildWithFirsCopyButton(
          context: context,
          icon: PhosphorIcons.share(),
          onTap: () async {
            await Share.share(encryptionKey);
          },
          lang: lang,
        ),
        // 1Password (no platform restriction)
        if (isOnePasswordInstalled)
          _buildActionButton(
             context: context,
             lang: lang,
            icon: Icons.security,
            onTap: () => openOnePassword(context: context),
           
          ),
        // Bitwarden (no platform restriction)
        if (isBitwardenInstalled)
          _buildActionButton(
            context: context,
            lang: lang,
            icon: Icons.vpn_key,
            onTap: () => openBitwarden(context: context),
           
          ),
        // Keeper (iOS only)
        if (isKeeperInstalled && Platform.isIOS)
          _buildActionButton(
            context: context,
            lang: lang,
            icon: Icons.lock_person,
            onTap: () => openKeeper(context: context),
           
          ),
        // LastPass (iOS only)
        if (isLastPassInstalled && Platform.isIOS)
          _buildActionButton(
            context: context,
            lang: lang,
            icon: Icons.password,
            onTap: () => openLastPass(context: context),
           
          ),
        // Enpass (iOS only)
        if (isEnpassInstalled && Platform.isIOS)
          _buildActionButton(
            context: context,
            lang: lang,
            icon: PhosphorIcons.vault(),
            onTap: () => openEnpass(context: context),
           
          ),
        // ProtonPass (iOS only)
        if (isProtonPassInstalled && Platform.isIOS)
          _buildActionButton(
            context: context,
            lang: lang,
            icon: Icons.shield,
            onTap: () => openProtonPass(context: context),
           
          ),
      ].whereType<Widget>().toList(),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required L10n lang,
    required IconData icon,
    required VoidCallback onTap 
  }) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: encryptionKey));
        if (context.mounted) {
          EasyLoading.showSuccess(lang.keyCopied);
          onButtonPressed.call();
        }
        
        // Then perform the action
        if (!context.mounted) return;
        await Future.delayed(const Duration(seconds: 2));
        onTap();
      },
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

  Widget _buildWithFirsCopyButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required L10n lang,
  }) {
    return _buildActionButton(
      icon: icon,
      context: context,
      lang: lang,
      onTap: () async {
         await _buildShareContent(lang);
         if (!context.mounted) return;
         await Future.delayed(const Duration(seconds: 2));
         onTap();
      },
    );
  }
}

