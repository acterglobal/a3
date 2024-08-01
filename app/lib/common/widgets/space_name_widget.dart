import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceNameWidget extends ConsumerWidget {
  final String? spaceId;

  const SpaceNameWidget({super.key, this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildSpaceName(context, ref);
  }

  Widget _buildSpaceName(BuildContext context, WidgetRef ref) {
    String spaceName =
        ref.watch(roomDisplayNameProvider(spaceId!)).valueOrNull ?? '';
    return Text(
      '($spaceName)',
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}
