import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceOverview extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // get platform of context.
    final space = ref.watch(spaceProvider(spaceIdOrAlias));
    return space.when(
      data: (space) {
        final topic = space.topic();
        return Text(topic ?? 'no topic found');
      },
      error: (error, stack) => Text('Loading failed: $error'),
      loading: () => const Text('Loading'),
    );
  }
}
