import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SecurityPrivacyWidget extends ConsumerWidget {
  const SecurityPrivacyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Column(
      children: [
        securityPrivacyCard(
          context,
          ref,
          icon: PhosphorIconsRegular.warningOctagon,
          title: lang.sessions,
          subtitle: lang.unverifiedSessionsTitle(6),
          action: lang.review,
          color: Theme.of(context).colorScheme.error,
        ),
        securityPrivacyCard(
          context,
          ref,
          icon: PhosphorIconsRegular.warning,
          title: lang.encryptionBackupProvideKey,
          subtitle: lang.encryptionBackupProvideKeyExplainer,
          action: lang.encryptionBackupProvideKeyAction,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget securityPrivacyCard(
    BuildContext context,
    WidgetRef ref, {
    IconData? icon,
    String? title,
    String? subtitle,
    String? action,
    Color? color,
  }) {
    final titleTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontSize: 15,
        );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width -
                          100, // Account for padding and icon
                    ),
                    child: Text(
                      subtitle ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      // Handle review action
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      action ?? '',
                      style: titleTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
