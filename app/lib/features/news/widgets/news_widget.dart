import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_vertical_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::news_widget');

class NewsWidget extends ConsumerWidget {
  const NewsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsListLoader = ref.watch(newsListProvider(null));
    return newsListLoader.when(
      data: (newsList) {
        if (newsList.isEmpty) return newsEmptyStateUI(context);
        return NewsVerticalView(newsList: newsList);
      },
      error: (e, s) => newsErrorUI(context, e, s),
      loading: () => newsLoadingUI(),
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
}
