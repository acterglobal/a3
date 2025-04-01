import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/app_install_check_provider.dart';
import 'package:acter/features/share/action/shareTo.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EncryptionKeyManager extends ConsumerWidget {
  final String id;
  final String encryptionKey;

  const EncryptionKeyManager({
    super.key,
    required this.id,
    required this.encryptionKey,
  });

  Future<String> _buildShareContent() async {
    return 'id=$id-encryptionKey=$encryptionKey';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final is1PasswordInstalled =
        ref
            .watch(isAppInstalledProvider(ExternalApps.onePassword))
            .valueOrNull ==
        true;
    final isBitwardenInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.bitwarden)).valueOrNull ==
        true;
    final isKeeperInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.keeper)).valueOrNull ==
        true;
    final isLastPassInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.lastPass)).valueOrNull ==
        true;
    final isEnpassInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.enpass)).valueOrNull ==
        true;
    final isProtonPassInstalled =
        ref
            .watch(isAppInstalledProvider(ExternalApps.protonPass))
            .valueOrNull ==
        true;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.security,
          onTap:
              is1PasswordInstalled
                  ? () async {
                    final shareData = await _buildShareContent();
                    if (!context.mounted) return;
                    await shareToOnePassword(context: context, text: shareData);
                    if (context.mounted) {
                      EasyLoading.showToast(
                        'Password copied to clipboard. Please paste it in 1Password.',
                      );
                    }
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '1Password is not installed on your device',
                        ),
                      ),
                    );
                  },
          context: context,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.vpn_key,
          onTap:
              isBitwardenInstalled
                  ? () async {
                    final shareData = await _buildShareContent();
                    if (!context.mounted) return;
                    await shareToBitwarden(context: context, text: shareData);
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bitwarden is not installed on your device',
                        ),
                      ),
                    );
                  },
          context: context,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.lock_person,
          onTap:
              isKeeperInstalled
                  ? () async {
                    final shareData = await _buildShareContent();
                    if (!context.mounted) return;
                    await shareToKeeper(context: context, text: shareData);
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Keeper is not installed on your device'),
                      ),
                    );
                  },
          context: context,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.password,
          onTap:
              isLastPassInstalled
                  ? () async {
                    final shareData = await _buildShareContent();
                    if (!context.mounted) return;
                    await shareToLastPass(context: context, text: shareData);
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'LastPass is not installed on your device',
                        ),
                      ),
                    );
                  },
          context: context,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: PhosphorIcons.vault(),
          onTap:
              isEnpassInstalled
                  ? () async {
                    final shareData = await _buildShareContent();
                    if (!context.mounted) return;
                    await shareToEnpass(context: context, text: shareData);
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enpass is not installed on your device'),
                      ),
                    );
                  },
          context: context,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.shield,
          onTap:
              isProtonPassInstalled
                  ? () async {
                    final shareData = await _buildShareContent();
                    if (!context.mounted) return;
                    await shareToProtonPass(context: context, text: shareData);
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'ProtonPass is not installed on your device',
                        ),
                      ),
                    );
                  },
          context: context,
        ),
      ],
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
