import 'package:acter/features/search/widgets/quick_jump.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QuickJump(
      navigateTo: ({
        Routes? route,
        bool push = false,
        String? target,
        Future<void> Function(BuildContext)? custom,
      }) async {
        if (custom != null) {
          await custom(context);
        } else {
          if (route == null) {
            context.go(target!);
          } else {
            context.goNamed(route.name);
          }
        }
      },
      expand: true,
    );
  }
}
