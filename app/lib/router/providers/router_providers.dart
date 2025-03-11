import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports
import 'package:logging/logging.dart';

final _log = Logger('a3::router::router_providers');

class LocationStateNotifier extends StateNotifier<String> {
  LocationStateNotifier() : super('/') {
    setupListener();
  }

  void setupListener() {
    goRouter.routerDelegate.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        // it’s gotta be delayed for some reason or the value of the uri hasn’t
        // properly updated yet ...
        final newRoute = goRouter
            .routeInformationProvider
            .value
            .uri
            .pathSegments
            .join('/');

        // FIXME: goBranch doesn’t actually provide the proper final URL
        // read it up from the specific StatefulNavigationShell.
        // see https://github.com/flutter/flutter/issues/146610
        final actualRoute = switch (newRoute) {
          'chat' =>
            chatTabNavKey.currentContext != null
                ? StatefulNavigationShell.of(chatTabNavKey.currentContext!)
                    .widget
                    .shellRouteContext
                    .routerState
                    .uri
                    .pathSegments
                    .join('/')
                : newRoute,
          'activities' =>
            activitiesTabNavKey.currentContext != null
                ? StatefulNavigationShell.of(
                  activitiesTabNavKey.currentContext!,
                ).widget.shellRouteContext.routerState.uri.pathSegments.join(
                  '/',
                )
                : newRoute,
          'updates' =>
            updateTabNavKey.currentContext != null
                ? StatefulNavigationShell.of(updateTabNavKey.currentContext!)
                    .widget
                    .shellRouteContext
                    .routerState
                    .uri
                    .pathSegments
                    .join('/')
                : newRoute,
          '/' =>
            homeTabNavKey.currentContext != null
                ? StatefulNavigationShell.of(homeTabNavKey.currentContext!)
                    .widget
                    .shellRouteContext
                    .routerState
                    .uri
                    .pathSegments
                    .join('/')
                : newRoute,
          'search' =>
            searchTabNavKey.currentContext != null
                ? StatefulNavigationShell.of(searchTabNavKey.currentContext!)
                    .widget
                    .shellRouteContext
                    .routerState
                    .uri
                    .pathSegments
                    .join('/')
                : newRoute,
          _ => newRoute,
        };
        state = '/$actualRoute';
        _log.info('Routing updated: /$actualRoute');
      });
    });
  }
}

final currentRoutingLocation =
    StateNotifierProvider<LocationStateNotifier, String>(
      (ref) => LocationStateNotifier(),
    );
