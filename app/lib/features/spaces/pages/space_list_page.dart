import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:acter/features/spaces/widgets/space_list_empty_state.dart';
import 'package:acter/features/spaces/widgets/space_list_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceListPage extends ConsumerStatefulWidget {
  final String? searchQuery;

  const SpaceListPage({
    super.key,
    this.searchQuery,
  });

  @override
  ConsumerState<SpaceListPage> createState() => _AllPinsPageConsumerState();
}

class _AllPinsPageConsumerState extends ConsumerState<SpaceListPage> {
  String get searchValue => ref.watch(searchValueProvider);

  @override
  void initState() {
    super.initState();
    widget.searchQuery.map((query) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(searchValueProvider.notifier).state = query;
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
    final lang = L10n.of(context);
    return AppBar(
      centerTitle: false,
      title: Text(L10n.of(context).spaces),
      actions: [
        PopupMenuButton(
          key: SpacesKeys.mainActions,
          icon: const Icon(Atlas.plus_circle),
          iconSize: 28,
          color: Theme.of(context).colorScheme.surface,
          itemBuilder: (BuildContext context) => <PopupMenuEntry>[
            PopupMenuItem(
              key: SpacesKeys.actionCreate,
              onTap: () => context.pushNamed(Routes.createSpace.name),
              child: Row(
                children: <Widget>[
                  Text(lang.createSpace),
                  const Spacer(),
                  const Icon(Atlas.connection),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () {
                context.pushNamed(Routes.searchPublicDirectory.name);
              },
              child: Row(
                children: <Widget>[
                  Text(lang.joinSpace),
                  const Spacer(),
                  const Icon(Atlas.calendar_dots),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          initialText: widget.searchQuery,
          onChanged: (value) {
            ref.read(searchValueProvider.notifier).state = value;
          },
          onClear: () {
            ref.read(searchValueProvider.notifier).state = '';
          },
        ),
        Expanded(
          child: SpaceListWidget(
            shrinkWrap: false,
            searchValue: searchValue,
            emptyState: SpaceListEmptyState(searchValue: searchValue),
          ),
        ),
      ],
    );
  }
}
