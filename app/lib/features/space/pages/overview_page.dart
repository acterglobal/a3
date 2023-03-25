import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceOverview extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;
  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceOverviewState();
}

class _SpaceOverviewState extends ConsumerState<SpaceOverview> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    final space = ref.watch(spaceProvider(widget.spaceIdOrAlias));
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
