import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class PinListEmptyState extends ConsumerWidget {
  final String? spaceId;
  final bool isSearchApplied;

  const PinListEmptyState({
    super.key,
    this.spaceId,
    this.isSearchApplied = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var canAdd = false;
    if (!isSearchApplied) {
      final canPostLoader = ref.watch(
        hasSpaceWithPermissionProvider('CanPostPin'),
      );
      if (canPostLoader.valueOrNull == true) canAdd = true;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title:
            isSearchApplied
                ? L10n.of(context).noMatchingPinsFound
                : L10n.of(context).noPinsAvailableYet,
        subtitle: L10n.of(context).noPinsAvailableDescription,
        image: 'assets/images/empty_pin.svg',
        primaryButton:
            canAdd
                ? ActerPrimaryActionButton(
                  onPressed:
                      () => context.pushNamed(
                        Routes.createPin.name,
                        queryParameters: {'spaceId': spaceId},
                      ),
                  child: Text(L10n.of(context).createPin),
                )
                : null,
      ),
    );
  }
}
