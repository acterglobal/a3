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

enum NewsViewMode { gridView, fullView }

class NewsListPage extends ConsumerStatefulWidget {
  final String? spaceId;
  final NewsViewMode newsViewMode;

  const NewsListPage({
    super.key,
    this.spaceId,
    this.newsViewMode = NewsViewMode.gridView,
  });

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final ValueNotifier<bool> gridMode = ValueNotifier(true);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    gridMode.value = widget.newsViewMode == NewsViewMode.gridView;
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
    final canPop = widget.newsViewMode == NewsViewMode.gridView &&
        this.gridMode.value == true;
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: false,
      leading: widget.newsViewMode == NewsViewMode.gridView
          ? IconButton(
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  this.gridMode.value = true;
                }
              },
              icon: const Icon(Icons.arrow_back),
            )
          : const SizedBox.shrink(),
      title: widget.newsViewMode == NewsViewMode.gridView
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).updates),
                if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
              ],
            )
          : const SizedBox.shrink(),
      actions: [
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
