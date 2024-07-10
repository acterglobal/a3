import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/invite_members/providers/invite_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

class PinsListPage extends ConsumerStatefulWidget {
  final String? spaceId;

  const PinsListPage({super.key, this.spaceId});

  @override
  ConsumerState<PinsListPage> createState() => _AllPinsPageConsumerState();
}

class _AllPinsPageConsumerState extends ConsumerState<PinsListPage> {
  final TextEditingController searchTextController = TextEditingController();
  bool hasSearchTerm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).pins),
          if (widget.spaceId != null) _buildSpaceName(),
        ],
      ),
      actions: [
        AddButtonWithCanPermission(
          canPermissionParam: widget.spaceId != null
              ? (spaceId: widget.spaceId!, canString: 'CanPostPin')
              : null,
          onPressed: () => context.pushNamed(
            Routes.actionAddPin.name,
            queryParameters:
                widget.spaceId != null ? {'spaceId': widget.spaceId} : {},
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceName() {
    String spaceName =
        ref.watch(roomDisplayNameProvider(widget.spaceId!)).valueOrNull ?? '';
    return Text(
      '($spaceName)',
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  Widget _buildBody() {
    AsyncValue<List<ActerPin>> pinList;

    final searchValue = ref.watch(searchValueProvider) ?? '';
    hasSearchTerm = searchValue.isNotEmpty;

    if (hasSearchTerm) {
      pinList = ref.watch(
        pinListSearchProvider(
          (spaceId: widget.spaceId, searchText: searchValue),
        ),
      );
    } else {
      pinList = ref.watch(pinListProvider(widget.spaceId));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        Expanded(
          child: pinList.when(
            data: (pins) => _buildPinsList(pins),
            error: (error, stack) =>
                Center(child: Text(L10n.of(context).loadingFailed(error))),
            loading: () => Center(child: Text(L10n.of(context).loading)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Atlas.magnifying_glass),
        ),
        hintText: L10n.of(context).search,
        trailing: hasSearchTerm
            ? [
                IconButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(searchValueProvider.notifier).state = '';
                    searchTextController.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ]
            : null,
        onChanged: (value) =>
            ref.read(searchValueProvider.notifier).state = value,
      ),
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
          for (var pin in pins)
            PinListItemById(
              pinId: pin.eventIdStr(),
              showSpace: widget.spaceId == null,
            ),
        ],
      ),
    );
  }

  Widget _buildPinsEmptyState() {
    bool canAdd = true;
    if (widget.spaceId != null && !hasSearchTerm) {
      final membership = ref.watch(roomMembershipProvider(widget.spaceId!));
      canAdd = membership.valueOrNull?.canString('CanPostPin') == true;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: hasSearchTerm
            ? L10n.of(context).noMatchingPinsFound
            : L10n.of(context).noPinsAvailableYet,
        subtitle: L10n.of(context).noPinsAvailableDescription,
        image: 'assets/images/empty_pin.svg',
        primaryButton: canAdd && !hasSearchTerm
            ? ActerPrimaryActionButton(
                onPressed: () => context.pushNamed(
                  Routes.actionAddPin.name,
                  queryParameters:
                      widget.spaceId != null ? {'spaceId': widget.spaceId} : {},
                ),
                child: Text(L10n.of(context).createPin),
              )
            : null,
      ),
    );
  }
}
