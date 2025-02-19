import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceNameWidget extends ConsumerWidget {
  final String spaceId;
  final bool isShowBrackets;
  final bool isShowUnderline;

  const SpaceNameWidget({
    super.key,
    required this.spaceId,
    this.isShowBrackets = true,
    this.isShowUnderline = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildSpaceName(context, ref);
  }

  Widget _buildSpaceName(BuildContext context, WidgetRef ref) {
    String spaceName =
        ref.watch(roomDisplayNameProvider(spaceId)).valueOrNull ?? spaceId;
    if (isShowBrackets) spaceName = '($spaceName)';
    return Text(
      spaceName,
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            decoration: isShowUnderline ? TextDecoration.underline : null,
          ),
    );
  }
}
