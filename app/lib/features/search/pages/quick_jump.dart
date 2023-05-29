import 'package:acter/features/search/widgets/quick_jump.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickjumpDialog extends ConsumerWidget {
  const QuickjumpDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400.0),
      child: Scaffold(
        appBar: AppBar(title: const Text('jump to')),
        body: QuickJump(
          navigateTo: ({Routes? route, bool push = false, String? target}) {
            context.pop();
            if (push) {
              if (route != null) {
                return context.pushNamed(route.name);
              }
              return context.push(target!);
            } else {
              if (route != null) {
                return context.goNamed(route.name);
              }
              return context.go(target!);
            }
          },
          expand: false,
        ),
      ),
    );
  }
}
