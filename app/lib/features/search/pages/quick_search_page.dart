import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter/features/spaces/widgets/space_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class QuickSearchPage extends ConsumerStatefulWidget {
  const QuickSearchPage({super.key});

  @override
  ConsumerState<QuickSearchPage> createState() => _QuickSearchPageState();
}

class _QuickSearchPageState extends ConsumerState<QuickSearchPage> {
  String get searchValue => ref.watch(quickSearchValueProvider);

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
      title: Text(L10n.of(context).search),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          onChanged: (value) {
            final notifier = ref.read(quickSearchValueProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(quickSearchValueProvider.notifier);
            notifier.state = '';
          },
        ),
        Expanded(child: quickSearchSectionsUI()),
      ],
    );
  }

  Widget quickSearchSectionsUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpaceListWidget(
            limit: 3,
            searchValue: searchValue,
            showSectionHeader: true,
            onClickSectionHeader: () => context.pushNamed(Routes.spaces.name),
          ),
          PinListWidget(
            limit: 3,
            searchValue: searchValue,
            showSectionHeader: true,
            onClickSectionHeader: () => context.pushNamed(
              Routes.pins.name,
              queryParameters: {'searchQuery': searchValue},
            ),
          ),
        ],
      ),
    );
  }
}
