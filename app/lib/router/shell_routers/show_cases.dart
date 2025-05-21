import 'package:acter/router/routes.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/chat_ng/pages/chat_room.dart';
import 'package:acter/features/chat_ui_showcase/pages/chat_list_showcase_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
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
        ]
        : List<GoRoute>.empty();
