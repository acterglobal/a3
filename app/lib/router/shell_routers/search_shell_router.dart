import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/pages/search.dart';
import 'package:acter/router/router.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> makeSearchShellRoutes(ref) {
  return [
    GoRoute(
      name: Routes.search.name,
      path: Routes.search.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const SearchPage(),
        );
      },
    ),
  ];
}
