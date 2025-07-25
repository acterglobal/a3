import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/onboarding/pages/encrption_backup_page.dart';
import 'package:acter/features/onboarding/pages/onboarding_encryption_recovery_page.dart';
import 'package:acter/features/showcases/pages/invitations/invitations_section.dart';
import 'package:acter/features/showcases/pages/showcase_list_page.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/chat_ng/pages/chat_room.dart';
import 'package:acter/features/chat_ui_showcase/pages/chat_list_showcase_page.dart';
import 'package:acter/features/activity_ui_showcase/pages/activity_list_showcase_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final List<GoRoute> showCaseRoutes =
    includeShowCases
        ? [
          // Chat
          GoRoute(
            name: Routes.chatListShowcase.name,
            path: Routes.chatListShowcase.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: ChatListShowcasePage(),
              );
            },
          ),
          GoRoute(
            name: Routes.chatRoomShowcase.name,
            path: Routes.chatRoomShowcase.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              return MaterialPage(
                key: state.pageKey,
                child: ChatRoomNgPage(roomId: roomId ?? ''),
              );
            },
          ),

          // Activities
          GoRoute(
            name: Routes.activityListShowcase.name,
            path: Routes.activityListShowcase.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: ActivityListShowcasePage(),
              );
            },
          ),


          // onboarding
          GoRoute(
            name: Routes.showCaseOnboardingEncryptionBackup.name,
            path: Routes.showCaseOnboardingEncryptionBackup.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: ProviderScope(
                  overrides: [
                    enableEncrptionBackUpProvider.overrideWith(
                      (ref) => Future.value('test-encryption-key'),
                    ),
                  ],
                  child: EncryptionBackupPage(
                    callNextPage: () {
                      context.pop();
                    },
                  ),
                ),
              );
            },
          ),
          GoRoute(
            name: Routes.showCaseOnboardingEncryptionRecovery.name,
            path: Routes.showCaseOnboardingEncryptionRecovery.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: OnboardingEncryptionRecoveryPage(
                  callNextPage: () {
                    context.pop();
                  },
                ),
              );
            },
          ),

          GoRoute(
            name: Routes.invitationsSectionShowcase.name,
            path: Routes.invitationsSectionShowcase.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: InvitationsSectionShowcasePage(),
              );
            },
          ),

          // index
          GoRoute(
            name: Routes.showcaseList.name,
            path: Routes.showcaseList.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: ShowcaseListPage(),
              );
            },
          ),
        ]
        : List<GoRoute>.empty();
