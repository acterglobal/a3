import 'package:acter/features/search/widgets/quick_jump.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Map<String, String> empty = {};

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: QuickJump(
        expand: true,
      ),
    );
  }
}
