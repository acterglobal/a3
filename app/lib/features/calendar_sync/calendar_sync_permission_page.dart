import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class CalendarSyncPermissionWidget extends ConsumerWidget {
  final void Function(BuildContext context) _callNextPage;
  // if this doesn't have any next step passed, adopt the design
  final bool _isStandalone;

  CalendarSyncPermissionWidget({super.key, CallNextPage? callNextPage})
    : _isStandalone = callNextPage == null,
      _callNextPage =
          callNextPage != null
              ? ((ctx) => callNextPage())
              : ((BuildContext context) => Navigator.pop(context, false));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button at the top right
            if (_isStandalone)
              Positioned(
                top: 20,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ),
            // Main content centered
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIcon(context),
                      const SizedBox(height: 20),
                      _buildTitleText(context, lang, textTheme),
                      const SizedBox(height: 20),
                      _buildDescriptionText(lang, textTheme),
                      const SizedBox(height: 20),
                      _buildActionButton(context, lang, textTheme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icon at the top of the page
  Widget _buildIcon(BuildContext context) {
    return Icon(
      Icons.calendar_month_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 100,
    );
  }

  // Title text for the page
  Widget _buildTitleText(BuildContext context, L10n lang, TextTheme textTheme) {
    return Text(
      lang.calendarSync,
      style: textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Description text for the page
  Widget _buildDescriptionText(L10n lang, TextTheme textTheme) {
    return Text(
      lang.calendarSyncDesc,
      style: textTheme.bodyMedium,
      textAlign: TextAlign.center,
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
            // Request Calendar Sync permission on button press
            await _requestCalendarSyncPermission(
              context,
              lang: lang,
              textStyle: textTheme.bodyMedium,
            );
          },
          child: Text(lang.continueLabel),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => _callNextPage(context),
          child: Text(_isStandalone ? lang.close : lang.skip),
        ),
      ],
    );
  }

  // Request calendar sync permission
  Future<void> _requestCalendarSyncPermission(
    BuildContext context, {
    required L10n lang,
    TextStyle? textStyle,
  }) async {
    final status = await Permission.calendarFullAccess.request();

    if (status.isGranted) {
      if (context.mounted) {
        _callNextPage(context);
      }
    } else if (status.isDenied) {
      // Permission denied, show a snack bar
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lang.calendarPermissionDenied)));
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
