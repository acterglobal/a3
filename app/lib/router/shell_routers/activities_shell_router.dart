import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/invitations/pages/invites_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final activitiesShellRoutes = [
  GoRoute(
    name: Routes.activities.name,
    path: Routes.activities.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(key: state.pageKey, child: const ActivitiesPage());
    },
  ),
  GoRoute(
    name: Routes.myOpenInvitations.name,
    path: Routes.myOpenInvitations.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(key: state.pageKey, child: const InvitesPage());
    },
  ),
];
