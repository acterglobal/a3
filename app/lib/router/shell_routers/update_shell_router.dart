import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:acter/router/router.dart';
import 'package:go_router/go_router.dart';

final updateShellRoutes = [
  GoRoute(
    name: Routes.updates.name,
    path: Routes.updates.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const NewsListPage(newsViewMode: NewsViewMode.fullView),
      );
    },
  ),
];
