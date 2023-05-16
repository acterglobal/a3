import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/search/widgets/quickjump.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QuickJump(
      navigateTo: (ctx, target) => ctx.push(target),
      expand: true,
    );
  }
}
