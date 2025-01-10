import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

Future<void> forwardToObject(
  BuildContext context,
  WidgetRef ref,
  UriParseResult result,
) async {
  final target = result.objectPath;
  final lang = L10n.of(context);
  if (target == null) {
    return EasyLoading.showError(
      lang.deepLinkNotSupported('missing object'),
      duration: const Duration(seconds: 3),
    );
  }
  final objectId = target.objectId;

  // FIXME: add lookup or preview capabilities
  final _ = switch (target.objectType) {
    ObjectType.pin =>
      context.pushNamed(Routes.pin.name, pathParameters: {'pinId': objectId}),
    ObjectType.taskList => context.pushNamed(
        Routes.taskListDetails.name,
        pathParameters: {'taskListId': objectId},
      ),
    ObjectType.calendarEvent => context.pushNamed(
        Routes.calendarEvent.name,
        pathParameters: {'calendarId': objectId},
      ),
    ObjectType.boost => context.pushNamed(
        Routes.update.name,
        pathParameters: {'updateId': objectId},
      ),
    _ => EasyLoading.showError(
        lang.deepLinkNotSupported(target.objectType),
        duration: const Duration(seconds: 3),
      ),
  };
}
