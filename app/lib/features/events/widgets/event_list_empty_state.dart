import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class EventListEmptyState extends ConsumerWidget {
  final String? spaceId;
  final bool isSearchApplied;

  const EventListEmptyState({
    super.key,
    this.spaceId,
    this.isSearchApplied = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var canAdd = false;
    if (!isSearchApplied) {
      final canPostLoader =
          ref.watch(hasSpaceWithPermissionProvider('CanPostEvent'));
      if (canPostLoader.valueOrNull == true) canAdd = true;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: isSearchApplied
            ? L10n.of(context).noMatchingEventsFound
            : L10n.of(context).noEventsFound,
        subtitle: L10n.of(context).noEventAvailableDescription,
        image: 'assets/images/empty_event.svg',
        primaryButton: canAdd
            ? ActerPrimaryActionButton(
                onPressed: () => context.pushNamed(
                  Routes.createEvent.name,
                  queryParameters: {'spaceId': spaceId},
                ),
                child: Text(L10n.of(context).addEvent),
              )
            : null,
      ),
    );
  }
}
