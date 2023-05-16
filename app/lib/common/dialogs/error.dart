import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/main/routing/routing.dart';
import 'package:acter/main/routing/routes.dart';

class ErrorPage extends ConsumerWidget {
  final GoRouterState routerState;
  const ErrorPage({
    super.key,
    required this.routerState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(currentRoutingLocation);
    return Scaffold(
      appBar: AppBar(title: const Text('404 - oopsie')),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: SvgPicture.asset('assets/images/genericError.svg'),
            ),
            Text(
                'How did you get here? There is nothing to see at `$currentLocation`...'),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(
                    Atlas.home_thin,
                  ),
                  label: const Text('Go to home'),
                  onPressed: () => context.goNamed(Routes.main.name),
                ),
                OutlinedButton.icon(
                  icon: const Icon(
                    Atlas.bug_clipboard_thin,
                  ),
                  label: const Text('Report bug'),
                  onPressed: () => context.goNamed(Routes.bugReport.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
