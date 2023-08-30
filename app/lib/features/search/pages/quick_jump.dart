import 'package:acter/features/search/widgets/quick_jump.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickjumpDialog extends ConsumerWidget {
  const QuickjumpDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Scaffold(
        appBar: AppBar(title: const Text('jump to')),
        body: QuickJump(
          navigateTo: ({
            Routes? route,
            bool push = false,
            String? target,
          }) async {
            context.pop();
            if (push) {
              if (route == null) {
                await context.push(target!);
              } else {
                await context.pushNamed(route.name);
              }
            } else {
              if (route == null) {
                context.go(target!);
              } else {
                context.goNamed(route.name);
              }
            }
          },
          expand: false,
        ),
      ),
    );
  }
}
