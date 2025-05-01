import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NotificationPermissionWidget extends ConsumerWidget {
  final CallNextPage? callNextPage;

  const NotificationPermissionWidget({super.key, this.callNextPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIcon(context),
                  const SizedBox(height: 20),
                  _buildTitleText(context, lang, textTheme),
                  const SizedBox(height: 20),
                  _buildDescriptionText(lang, textTheme),
                  const SizedBox(height: 20),
                  _buildStuffItems(context, lang),
                  const SizedBox(height: 20),
                  _buildActionButton(context, lang, textTheme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Icon at the top of the page
  Widget _buildIcon(BuildContext context) {
    return Column(
      children: [
        if (callNextPage == null)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close),
            ),
          ),
        Icon(
          PhosphorIcons.bell(),
          color: Theme.of(context).colorScheme.primary,
          size: 100,
        ),
      ],
    );
  }

  // Title text for the page
  Widget _buildTitleText(BuildContext context, L10n lang, TextTheme textTheme) {
    return Text(
      lang.pushNotification,
      style: textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Description text for the page
  Widget _buildDescriptionText(L10n lang, TextTheme textTheme) {
    return Text(
      lang.pushNotificationDesc,
      style: textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  // Build the list of "stuff items" for the page
  Widget _buildStuffItems(BuildContext context, L10n lang) {
    final stuffItems = [
      lang.directInvitation,
      lang.msgFromChat,
      lang.boostFromPeers,
      lang.commentOnThings,
      lang.subscribeTo,
    ];

    List<Widget> itemWidgets =
        stuffItems.map((item) {
          return buildStuffItem(text: item, context: context);
        }).toList();

    // Add the spam item with a custom icon and color
    itemWidgets.add(
      buildStuffItem(
        icon: Icons.cancel_outlined,
        text: lang.spam,
        context: context,
        iconColor: Theme.of(context).colorScheme.error,
      ),
    );

    return Column(children: itemWidgets);
  }

  // Builds each item in the list of notifications
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? PhosphorIcons.checkCircle(),
            color: iconColor ?? Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // Action button for allowing permission or asking again
  Widget _buildActionButton(
    BuildContext context,
    L10n lang,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () async {
            // Request notification permission on button press
            await _requestNotificationPermission(
              context,
              lang: lang,
              textStyle: textTheme.bodyMedium,
            );
          },
          child: Text(lang.allowPermission),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            if (context.mounted) {
              (callNextPage?.call ?? () => Navigator.pop(context, false))();
            }
          },
          child: Text(lang.askAgain),
        ),
      ],
    );
  }

  // Request notification permission
  Future<void> _requestNotificationPermission(
    BuildContext context, {
    required L10n lang,
    TextStyle? textStyle,
  }) async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      if (context.mounted) {
        (callNextPage?.call ?? () => Navigator.pop(context, true))();
      }
    } else if (status.isDenied) {
      // Permission denied, show a snack bar
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lang.notificationDenied)));
      }
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show option to go to settings
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.permissionPermantlyDenied, style: textStyle),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => openAppSettings(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    lang.goToSettings,
                    style: textStyle?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
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
