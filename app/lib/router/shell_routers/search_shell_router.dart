import 'package:acter/router/routes.dart';
import 'package:acter/features/search/pages/quick_search_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final searchShellRoutes = [
  GoRoute(
    name: Routes.search.name,
    path: Routes.search.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(key: state.pageKey, child: const QuickSearchPage());
    },
  ),
];
