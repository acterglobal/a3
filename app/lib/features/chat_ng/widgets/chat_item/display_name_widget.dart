import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat-item::display-name-widget');

class DisplayNameWidget extends ConsumerWidget {
  final String roomId;
  final TextStyle? style;

  const DisplayNameWidget({super.key, required this.roomId, this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayNameProvider = ref.watch(roomDisplayNameProvider(roomId));
    return displayNameProvider.when(
      data: (displayName) => _renderDisplayName(context, displayName),
      error: (e, s) {
        _log.severe('Failed to load displayName', e, s);
        return const SizedBox.shrink();
      },
      loading:
          () =>
              Skeletonizer(child: _renderDisplayName(context, 'Display Name')),
    );
  }

  Widget _renderDisplayName(BuildContext context, String? displayName) {
    return Text(
      displayName ?? roomId,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
