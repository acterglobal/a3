import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NotificationPermissionPage extends ConsumerWidget {
  const NotificationPermissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                PhosphorIcons.bell(),
                color: Theme.of(context).colorScheme.secondary,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                lang.pushNotification,
                style: textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                lang.pushNotificationDesc,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              buildStuffItem(text: lang.directInvitation, context: context),
              buildStuffItem(text: lang.msgFromChat, context: context),
              buildStuffItem(text: lang.boostFromPeers, context: context),
              buildStuffItem(text: lang.commentOnThings, context: context),
              buildStuffItem(text: lang.subscribeTo, context: context),
              buildStuffItem(
                icon: Icons.cancel_outlined,
                text: lang.spam,
                context: context,
                iconColor: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              _buildActionButton(context, lang),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStuffItem({
    required BuildContext context,
    IconData? icon,
    required String text,
    double spacing = 10,
    Color? iconColor,
    TextStyle? textStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 20),
      child: Row(
        children: [
          Icon(
            icon ?? PhosphorIcons.checkCircle(),
            color: iconColor ?? Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: spacing),
          Text(
            text,
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {},
          child: Text(
            lang.allowPermission,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: () {}, child: Text(lang.askAgain)),
      ],
    );
  }
}
