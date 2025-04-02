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
      appBar: _buildAppBar(context),
      body: _buildBody(context, lang, textTheme, ref),
    );
  }

  // AppBar for the Notification Permission Page
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.goNamed(Routes.main.name),
          tooltip: 'Close',
        ),
      ],
    );
  }

  // Body content of the Notification Permission Page
  Widget _buildBody(
    BuildContext context,
    L10n lang,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildIcon(context),
              const SizedBox(height: 20),
              _buildTitleText(context, lang, textTheme),
              const SizedBox(height: 20),
              _buildDescriptionText(lang, textTheme),
              const SizedBox(height: 20),
              _buildStuffItems(context, lang),
              const SizedBox(height: 20),
              _buildActionButton(context, lang, ref, textTheme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Icon at the top of the page
  Widget _buildIcon(BuildContext context) {
    return Icon(
      PhosphorIcons.bell(),
      color: Theme.of(context).colorScheme.primary,
      size: 100,
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

    List<Widget> itemWidgets = stuffItems.map((item) {
      return buildStuffItem(text: item, context: context);
    }).toList();

    // Add the spam item with a custom icon and color
    itemWidgets.add(buildStuffItem(
      icon: Icons.cancel_outlined,
      text: lang.spam,
      context: context,
      iconColor: Theme.of(context).colorScheme.error,
    ));

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
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              icon ?? PhosphorIcons.checkCircle(),
              color: iconColor ?? Theme.of(context).colorScheme.secondary,
            ),
          ),
          SizedBox(width: spacing),
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
    WidgetRef ref,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () async {
            // Request notification permission on button press
            await _requestNotificationPermission(context, textStyle: textTheme.bodyMedium);
          },
          child: Text(lang.allowPermission),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            if (context.mounted) {
              // Navigate back to main page
              context.goNamed(Routes.main.name);
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
    TextStyle? textStyle,
  }) async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      // Permission granted, navigate to main page
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    } else if (status.isDenied) {
      // Permission denied, show a snack bar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification permission denied.')),
        );
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
                  child: Text(
                    'Go to Settings',
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
