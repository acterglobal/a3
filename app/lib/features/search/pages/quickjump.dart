import 'package:acter/features/search/widgets/quickjump.dart';
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
          navigateTo: (ctx, target) => ctx.go(target),
          expand: false,
        ),
      ),
    );
  }
}
