import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

class EncryptionBackupPage extends ConsumerStatefulWidget {
  const EncryptionBackupPage({super.key});

  @override
  ConsumerState<EncryptionBackupPage> createState() =>
      _EncryptionBackupPageState();
}

class _EncryptionBackupPageState extends ConsumerState<EncryptionBackupPage> {
  final ValueNotifier<bool> isShowNextButton = ValueNotifier(false);
  final ValueNotifier<String> encryptionKey = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    enableBackup(context);
  }

  void enableBackup(BuildContext context) async {
    try {
      encryptionKey.value = await ref.read(
        enableEncrptionBackUpProvider.future,
      );
      isShowNextButton.value = true;
    } catch (e) {
      encryptionKey.value = e.toString();
    }
  }

  @override
  void dispose() {
    isShowNextButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              PhosphorIcons.lockKey(),
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            _buildHeader(context, lang),
            const SizedBox(height: 16),
            _buildDescription(context, lang),
            const SizedBox(height: 32),
            _buildEncryptionKey(context),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const Spacer(),
            _buildNavigationButtons(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, L10n lang) {
    return Text(
      lang.encryptionKeyBackupTitle,
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context, L10n lang) {
    return Text(
      lang.encryptionKeyBackupDescription,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEncryptionKey(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: encryptionKey,
        builder: (context, key, _) {
          if (key.isEmpty) {
            return const Center(child: LinearProgressIndicator());
          }
          return SelectableText(
            key,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 16, letterSpacing: 1.2),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.copy,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: encryptionKey.value));
            isShowNextButton.value = true;
            if (context.mounted) {
              EasyLoading.showToast(
                L10n.of(context).encryptionBackupRecoveryCopiedToClipboard,
              );
            }
          },
          context: context,
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: PhosphorIcons.share(),
          onTap: () async {
            await Share.share(encryptionKey.value);
            isShowNextButton.value = true;
          },
          context: context,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildNextButton(context, lang), const SizedBox(height: 16)],
    );
  }

  Widget _buildNextButton(BuildContext context, L10n lang) {
    return ValueListenableBuilder<bool>(
      valueListenable: isShowNextButton,
      builder: (context, isEnabled, _) {
        return ElevatedButton(
          onPressed:
              isEnabled ? () => context.goNamed(Routes.linkEmail.name) : null,
          child: Text(lang.next, style: const TextStyle(fontSize: 16)),
        );
      },
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
