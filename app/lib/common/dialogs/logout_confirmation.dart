import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/features/onboarding/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void confirmationDialog(BuildContext ctx, WidgetRef ref) {
  showDialog(
    context: ctx,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(
          'Logout',
          style: AppCommonTheme.appBarTitleStyle,
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logOut(ctx),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
