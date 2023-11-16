import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/pages/event_page.dart';
import 'package:acter/features/events/pages/events_page.dart';
import 'package:acter/features/pins/pages/pin_page.dart';
import 'package:acter/features/pins/pages/pins_page.dart';
import 'package:acter/features/search/pages/search.dart';
import 'package:acter/features/tasks/pages/tasks_page.dart';
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
    GoRoute(
      name: Routes.tasks.name,
      path: Routes.tasks.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const TasksPage(),
        );
      },
    ),
    GoRoute(
      name: Routes.pins.name,
      path: Routes.pins.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const PinsPage(),
        );
      },
    ),
    GoRoute(
      name: Routes.pin.name,
      path: Routes.pin.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: PinPage(pinId: state.pathParameters['pinId']!),
        );
      },
    ),
    GoRoute(
      name: Routes.calendarEvents.name,
      path: Routes.calendarEvents.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const EventsPage(),
        );
      },
    ),
    GoRoute(
      name: Routes.calendarEvent.name,
      path: Routes.calendarEvent.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: CalendarEventPage(
            calendarId: state.pathParameters['calendarId']!,
          ),
        );
      },
    ),
  ];
}
