import 'package:acter/features/desktop_setup/pages/desktop_setup_page.dart';
import 'package:flutter/material.dart';

/// Internal function to show the desktop setup dialog
Future<void> showDesktopSetup(BuildContext context) async {
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