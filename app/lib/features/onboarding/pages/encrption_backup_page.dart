import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:acter/features/onboarding/widgets/onboarding_progress_dots.dart';

class EncryptionBackupPage extends ConsumerStatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(bool) onEnabled;

  const EncryptionBackupPage({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onEnabled,
  });

  @override
  ConsumerState<EncryptionBackupPage> createState() =>
      _EncryptionBackupPageState();
}

class _EncryptionBackupPageState extends ConsumerState<EncryptionBackupPage> {
  final isEnableNextButton = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(PhosphorIcons.lockKey(), size: 80, color: primaryColor),
            const SizedBox(height: 24),
            _buildHeader(context, lang),
            const SizedBox(height: 16),
            _buildDescription(context, lang),
            const SizedBox(height: 32),
            _buildEncryptionKey(context),
            const Spacer(),
            _buildNavigationButtons(context, lang),
            OnboardingProgressDots(
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
            ),
            const SizedBox(height: 16),
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
    final encKey = ref.watch(enableEncrptionBackUpProvider);

    return encKey.when(
      data: (data) {
        return Column(
          children: [
            _buildEncryptionKeyContent(context, data),
            const SizedBox(height: 32),
            _buildActionButtons(context, data),
          ],
        );
      },
      error:
          (error, stack) => _buildEncryptionKeyError(context, error.toString()),
      loading: () => const Center(child: LinearProgressIndicator()),
    );
  }

  Widget _buildEncryptionKeyContent(BuildContext context, String encKey) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 16, letterSpacing: 1.2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(encKey, style: style, textAlign: TextAlign.center),
    );
  }

  Widget _buildEncryptionKeyError(BuildContext context, String error) {
    final errorColor = Theme.of(context).colorScheme.error;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: errorColor);
    return Center(
      child: Column(
        children: [
          Text(error, style: style),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: errorColor,
              side: BorderSide(color: errorColor),
            ),
            onPressed: () => ref.invalidate(enableEncrptionBackUpProvider),
            child: Text(L10n.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String encryptionKey) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.copy,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: encryptionKey));
            isEnableNextButton.value = true;
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
            await Share.share(encryptionKey);
            isEnableNextButton.value = true;
          },
          context: context,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNextButton(context, lang),
        const SizedBox(height: 16),
        _buidSkipButton(context, lang),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNextButton(BuildContext context, L10n lang) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnableNextButton,
      builder: (context, isEnabled, _) {
        return ElevatedButton(
          onPressed: () {  widget.onEnabled(true);},
          child: Text(lang.next, style: const TextStyle(fontSize: 16)),
        );
      },
    );
  }

  Widget _buidSkipButton(BuildContext context, L10n lang) {
    return OutlinedButton(onPressed: () {  widget.onEnabled(true);}, child: Text(L10n.of(context).skip));
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
