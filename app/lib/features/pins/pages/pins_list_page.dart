import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_empty_state.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PinsListPage extends ConsumerStatefulWidget {
  final String? spaceId;
  final String? searchQuery;

  const PinsListPage({
    super.key,
    this.spaceId,
    this.searchQuery,
  });

  @override
  ConsumerState<PinsListPage> createState() => _AllPinsPageConsumerState();
}

class _AllPinsPageConsumerState extends ConsumerState<PinsListPage> {
  String get _searchValue => ref.watch(pinListSearchTermProvider);

  @override
  void initState() {
    super.initState();
    widget.searchQuery.map((query) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(pinListSearchTermProvider.notifier).state = query;
      });
    });
  }

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
            queryParameters: {'spaceId': spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          initialText: _searchValue,
          onChanged: (value) {
            final notifier = ref.read(pinListSearchTermProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(pinListSearchTermProvider.notifier);
            notifier.state = '';
          },
        ),
        Expanded(
          child: PinListWidget(
            pinListProvider: pinListSearchedProvider(widget.spaceId),
            spaceId: widget.spaceId,
            shrinkWrap: false,
            searchValue: _searchValue,
            emptyState: PinListEmptyState(
              spaceId: widget.spaceId,
              isSearchApplied: _searchValue.isNotEmpty,
            ),
          ),
        ),
      ],
    );
  }
}
