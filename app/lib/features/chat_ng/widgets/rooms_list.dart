import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomsListNGWidget extends RoomsListWidget {
  const RoomsListNGWidget({
    required super.onSelected,
    super.key = RoomsListWidget.roomListMenuKey,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RoomsListNGWidgetState();
}

class _RoomsListNGWidgetState extends RoomsListWidgetState {
  @override
  Widget roomListTitle(BuildContext context) {
    final lang = L10n.of(context);
    String? title;

    if (ref.watch(hasRoomFilters)) {
      final selection =
          ref.watch(roomListFilterProvider.select((value) => value.selection));
      title = switch (selection) {
        FilterSelection.dmsOnly => lang.dms,
        FilterSelection.favorites => lang.bookmarked,
        _ => null,
      };
    }

    return Text(
      title ?? lang.chatNG,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
