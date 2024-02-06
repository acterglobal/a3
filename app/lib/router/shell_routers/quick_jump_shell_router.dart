import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/dialog_page.dart';
import 'package:acter/features/search/pages/quick_jump_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> makeQuickJumpShellRoutes(ref) {
  return [
    GoRoute(
      name: Routes.quickJump.name,
      path: Routes.quickJump.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) => DialogPage(
        builder: (BuildContext ctx) => const QuickjumpDialog(),
      ),
    ),
  ];
}
