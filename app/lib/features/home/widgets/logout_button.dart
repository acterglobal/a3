import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio/features/onboarding/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogOutButton extends ConsumerWidget {
  final bool isExtendedRail;
  const LogOutButton({required this.isExtendedRail, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(homeStateProvider.notifier).client.isGuest();
    return !isGuest
        ? IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logOut(context),
            icon: isExtendedRail
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const <Widget>[
                        Icon(
                          Icons.logout_outlined,
                          color: Colors.red,
                        ),
                        Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Icon(
                      Icons.logout_outlined,
                      color: Colors.red,
                    ),
                  ),
          )
        : const SizedBox.shrink();
  }
}
