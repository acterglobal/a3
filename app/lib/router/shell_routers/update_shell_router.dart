import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final updateShellRoutes = [
  GoRoute(
    name: Routes.updates.name,
    path: Routes.updates.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(
        key: state.pageKey,
        child: const NewsListPage(newsViewMode: NewsViewMode.fullView),
      );
    },
  ),
  GoRoute(
    name: Routes.update.name,
    path: Routes.update.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(
        key: state.pageKey,
        child: NewsListPage(
          newsViewMode: NewsViewMode.fullView,
          initialEventId: state.pathParameters['updateId'],
        ),
      );
    },
  ),
];
