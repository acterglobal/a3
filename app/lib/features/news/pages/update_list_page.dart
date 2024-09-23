import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::update::list');

class UpdateListPage extends ConsumerStatefulWidget {
  final String? spaceId;

  const UpdateListPage({super.key, this.spaceId});

  @override
  ConsumerState<UpdateListPage> createState() => _UpdateListPageState();
}

class _UpdateListPageState extends ConsumerState<UpdateListPage> {
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
    final newsListLoader = ref.watch(newsListProvider);

    return newsListLoader.when(
      data: (updateList) => _buildUpdateListUI(updateList),
      error: (error, stack) {
        _log.severe('Failed to load updates', error, stack);
        return ErrorPage(
          background: Container(),
          error: error,
          stack: stack,
          textBuilder: L10n.of(context).loadingFailed,
          onRetryTap: () {},
        );
      },
      loading: () => Container(),
    );
  }

  Widget _buildUpdateListUI(List<NewsEntry> updateList) {
    if (updateList.isEmpty) return Container();

    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: updateList.length,
      itemBuilder: (context, index) => updateItemUI(updateList[index], index),
    );
  }

  Widget updateItemUI(NewsEntry newsEntry, int index) {
    final List<NewsSlide> newsSlides = newsEntry.slides().toList();
    final slide = newsSlides[0];
    final slideType = slide.typeStr();
    final bgColor = convertColor(
      slide.colors()?.background(),
      Theme.of(context).colorScheme.surface,
    );

    return Container(
      height: index % 2 == 0 ? 300 : 200,
      color: bgColor,
      margin: const EdgeInsets.all(6),
      child: getSlideItem(slideType),
    );
  }

  Widget getSlideItem(slideType) {
    return switch (slideType) {
      'image' => const Icon(Icons.image),
      'video' => const Icon(Icons.video_collection),
      'text' => const Icon(Icons.text_fields),
      _ => Expanded(
          child: Center(
            child: Text(L10n.of(context).slidesNotYetSupported(slideType)),
          ),
        ),
    };
  }
}
