import 'package:acter/features/onboarding/pages/analytics_opt_in_page.dart';
import 'package:flutter/material.dart';

/// Internal function to handle analytics opt-in
Future<void> handleAnalyticsOptIn(BuildContext context) async {
  if (context.mounted) {
    await showDialog(
      context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog.fullscreen(child: const AnalyticsOptInWidget());
          },
    );
  }
}
