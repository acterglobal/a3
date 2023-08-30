import 'package:acter/common/widgets/error.dart';
import 'package:acter/router/providers/notifiers/router_notifier.dart';
import 'package:acter/router/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports

final routerNotifierProvider = AsyncNotifierProvider<RouterNotifier, void>(() {
  return RouterNotifier();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);
  return GoRouter(
    errorBuilder: (context, state) => ErrorPage(routerState: state),
    navigatorKey: rootNavKey,
    refreshListenable: notifier,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: notifier.routeList,
  );
});

final routeInformationProvider =
    ChangeNotifierProvider<GoRouteInformationProvider>((ref) {
  final router = ref.watch(goRouterProvider);
  return router.routeInformationProvider;
});

final currentRoutingLocation = Provider<String>((ref) {
  final uri = ref.watch(routeInformationProvider).value.uri;
  if (uri.hasEmptyPath) {
    return '/';
  }
  return uri.path;
});
