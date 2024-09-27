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
          Text(L10n.of(context).updates),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
        ],
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: gridMode,
          builder: (context, value, child) {
            return IconButton(
              onPressed: () {
                gridMode.value = !gridMode.value;
                currentIndex.value = 0;
              },
              icon: value
                  ? const Icon(Icons.fullscreen)
                  : const Icon(Icons.grid_view),
            );
          },
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

  Widget _buildBody() {
    final newsListLoader = ref.watch(newsListProvider(widget.spaceId));

    return newsListLoader.when(
      data: (newsList) {
        return ValueListenableBuilder(
          valueListenable: gridMode,
          builder: (context, value, child) {
            if (newsList.isEmpty) return newsEmptyStateUI(context);
            return value
                ? NewsGridView(
                    newsList: newsList,
                    onTapNewItem: (index) {
                      gridMode.value = !gridMode.value;
                      currentIndex.value = index;
                    },
                  )
                : NewsFullView(
                    newsList: newsList,
                    initialPageIndex: currentIndex.value,
                  );
          },
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
