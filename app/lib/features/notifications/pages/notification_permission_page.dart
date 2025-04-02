import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
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
            onPressed: () => context.goNamed(Routes.main.name),
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
                color: Theme.of(context).colorScheme.primary,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                lang.pushNotification,
                style: textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
              _buildActionButton(
                context,
                lang,
                ref,
                textStyle: textTheme.bodyMedium,
              ),
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

  Widget _buildActionButton(
    BuildContext context,
    L10n lang,
    WidgetRef ref, {
    TextStyle? textStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () async {
            // Request notification permission on button press
            await _requestNotificationPermission(context, textStyle: textStyle);
          },
          child: Text(
            lang.allowPermission,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () async {
            if (context.mounted) {
              // Permission is granted or restricted, proceed accordingly
              context.goNamed(Routes.main.name);
            }
          },
          child: Text(lang.askAgain),
        ),
      ],
    );
  }

  Future<void> _requestNotificationPermission(
    BuildContext context, {
    TextStyle? textStyle,
  }) async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      // Permission granted, navigate back to the main page or proceed with further actions
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    } else if (status.isDenied) {
      // If permission is denied, show the option to ask again\
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification permission denied.')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // If permission is permanently denied, show option to go to settings
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permission permanently denied. You can enable it in settings.',                  
                  style: textStyle,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => openAppSettings(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Go to Settings', style: textStyle?.copyWith(color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      }
    }
  }
}
