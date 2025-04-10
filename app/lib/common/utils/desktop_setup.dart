import 'package:acter/features/onboarding/pages/desktop_setup_page.dart';
import 'package:flutter/material.dart';

/// Internal function to handle desktop setup
Future<void> handleDesktopSetup(BuildContext context) async {
  if (context.mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog.fullscreen(child: const DesktopSetupWidget());
      },
    );
  }
}