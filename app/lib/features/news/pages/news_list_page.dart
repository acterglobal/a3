import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_full_view.dart';
import 'package:acter/features/news/widgets/news_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::list');

class NewsListPage extends ConsumerStatefulWidget {
  final String? spaceId;
  final bool gridMode;

  const NewsListPage({super.key, this.spaceId, this.gridMode = true});

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final ValueNotifier<bool> gridMode = ValueNotifier(true);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    gridMode.value = widget.gridMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: gridMode,
      builder: (context, value, child) {
        return Scaffold(
          extendBodyBehindAppBar: !value,
          appBar: _buildAppBar(value),
          body: _buildBody(value),
        );
      },
    );
  }

  AppBar _buildAppBar(bool gridMode) {
    final spaceId = widget.spaceId;
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).updates),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            this.gridMode.value = !this.gridMode.value;
            currentIndex.value = 0;
          },
          icon: gridMode
              ? const Icon(Icons.fullscreen)
              : const Icon(Icons.grid_view),
        ),
        AddButtonWithCanPermission(
          canString: 'CanPostNews',
          onPressed: () => context.pushNamed(
            Routes.actionAddUpdate.name,
            queryParameters: {'spaceId': widget.spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool gridMode) {
    final newsListLoader = ref.watch(newsListProvider(widget.spaceId));

    return newsListLoader.when(
      data: (newsList) {
        if (newsList.isEmpty) return newsEmptyStateUI(context);
        return gridMode
            ? NewsGridView(
                newsList: newsList,
                onTapNewItem: (index) {
                  this.gridMode.value = !this.gridMode.value;
                  currentIndex.value = index;
                },
              )
            : NewsFullView(
                newsList: newsList,
                initialPageIndex: currentIndex.value,
              );
      },
      error: (e, s) => newsErrorUI(context, e, s),
      loading: () => newsLoadingUI(),
    );
  }

  Widget newsLoadingUI() {
    return const Center(
      child: SizedBox(
        height: 50,
        width: 50,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget newsErrorUI(BuildContext context, e, s) {
    _log.severe('Failed to load news list', e, s);
    return Center(
      child: Text(L10n.of(context).couldNotFetchNews),
    );
  }

  Widget newsEmptyStateUI(BuildContext context) {
    return Center(
      child: EmptyState(
        title: L10n.of(context).youHaveNoUpdates,
        subtitle: L10n.of(context).createPostsAndEngageWithinSpace,
        image: 'assets/images/empty_updates.svg',
        primaryButton: ActerPrimaryActionButton(
          onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
          child: Text(L10n.of(context).createNewUpdate),
        ),
      ),
    );
  }
}
