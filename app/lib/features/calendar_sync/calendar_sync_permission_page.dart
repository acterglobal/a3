import 'dart:math';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarSyncPermissionWidget extends StatelessWidget {
  const CalendarSyncPermissionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button at the top right
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
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
            final SharedPreferences preferences = await sharedPrefs();

            final hasPermission = await deviceCalendar.hasPermissions();

            if (hasPermission.data == false) {
              final requesting = await deviceCalendar.requestPermissions();
              if (requesting.data == false) {
                await preferences.setBool(rejectionKey, true);
                return;
              }
              else {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          },
          child: Text(lang.allowPermission),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(lang.askAgain),
        ),
      ],
    );
  }
}
