import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::list');

class PinsListPage extends ConsumerStatefulWidget {
  final String? spaceId;

  const PinsListPage({
    super.key,
    this.spaceId,
  });

  @override
  ConsumerState<PinsListPage> createState() => _AllPinsPageConsumerState();
}

class _AllPinsPageConsumerState extends ConsumerState<PinsListPage> {
  String get searchValue => ref.watch(searchValueProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    final spaceId = widget.spaceId;
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).pins),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
        ],
      ),
      actions: [
        AddButtonWithCanPermission(
          canString: 'CanPostPin',
          spaceId: widget.spaceId,
          onPressed: () => context.pushNamed(
            Routes.createPin.name,
            queryParameters: {'spaceId': widget.spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final pinsLoader = searchValue.isNotEmpty
        ? ref.watch(
            pinListSearchProvider(
              (spaceId: widget.spaceId, searchText: searchValue),
            ),
          )
        : ref.watch(pinListProvider(widget.spaceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          onChanged: (value) =>
              ref.read(searchValueProvider.notifier).state = value,
          onClear: () => ref.read(searchValueProvider.notifier).state = '',
        ),
        Expanded(
          child: pinsLoader.when(
            data: (pins) => _buildPinsList(pins),
            error: (error, stack) {
              _log.severe('Failed to load pins', error, stack);
              return ErrorPage(
                background: const PinListSkeleton(),
                error: error,
                stack: stack,
                textBuilder: L10n.of(context).loadingFailed,
                onRetryTap: () {
                  if (searchValue.isNotEmpty) {
                    ref.invalidate(
                      pinListSearchProvider(
                        (spaceId: widget.spaceId, searchText: searchValue),
                      ),
                    );
                  } else {
                    ref.invalidate(pinListProvider(widget.spaceId));
                  }
                },
              );
            },
            loading: () => const PinListSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildPinsList(List<ActerPin> pins) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    if (pins.isEmpty) return _buildPinsEmptyState();

    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: max(1, min(widthCount, minCount)),
        children: [
          for (final pin in pins)
            PinListItemWidget(
              pinId: pin.eventIdStr(),
              showSpace: widget.spaceId == null,
            ),
        ],
      ),
    );
  }

  Widget _buildPinsEmptyState() {
    final lang = L10n.of(context);
    var canAdd = false;
    if (searchValue.isEmpty) {
      final canPostLoader = ref.watch(
        hasSpaceWithPermissionProvider('CanPostPin'),
      );
      if (canPostLoader.valueOrNull == true) canAdd = true;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: searchValue.isNotEmpty
            ? lang.noMatchingPinsFound
            : lang.noPinsAvailableYet,
        subtitle: lang.noPinsAvailableDescription,
        image: 'assets/images/empty_pin.svg',
        primaryButton: canAdd
            ? ActerPrimaryActionButton(
                onPressed: () => context.pushNamed(
                  Routes.createPin.name,
                  queryParameters: {'spaceId': widget.spaceId},
                ),
                child: Text(lang.createPin),
              )
            : null,
      ),
    );
  }
}
