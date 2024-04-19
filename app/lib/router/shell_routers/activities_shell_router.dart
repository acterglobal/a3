import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/router/router.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> makeActivitiesShellRoutes(ref) {
  return [
    GoRoute(
      name: Routes.activities.name,
      path: Routes.activities.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const ActivitiesPage(),
        );
      },
    ),
  ];
}
