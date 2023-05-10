import 'package:acter/common/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchSpacePage extends ConsumerWidget {
  const SearchSpacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(
        key: UniqueKey(),
        title: const Text('Search Space'),
        context: context,
      ),
      body: Container(),
    );
  }
}
