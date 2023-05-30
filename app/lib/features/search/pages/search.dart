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
      navigateTo: ({Routes? route, bool push = false, String? target}) {
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
      expand: true,
    );
  }
}
