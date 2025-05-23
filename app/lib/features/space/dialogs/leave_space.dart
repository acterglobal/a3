import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::leave_space');

const leaveSpaceYesBtn = Key('leave-space-yes-btn');

Future<void> showLeaveSpaceDialog(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) async {
  await showAdaptiveDialog(
    barrierDismissible: true,
    context: context,
    useRootNavigator: false,
    builder: (context) {
      final lang = L10n.of(context);
      return DefaultDialog(
        title: Column(
          children: <Widget>[
            const Icon(Icons.person_remove_outlined),
            const SizedBox(height: 5),
            Text(
              lang.leaveSpace,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        subtitle: Text(lang.areYouSureYouWantToLeaveSpace),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.noIStay),
          ),
          ActerDangerActionButton(
            key: leaveSpaceYesBtn,
            onPressed: () async {
              try {
                EasyLoading.show(status: lang.leavingSpace);
                final parentIds = await ref.read(
                  parentIdsProvider(spaceId).future,
                );
                final space = await ref.read(spaceProvider(spaceId).future);
                await space.leave();
                if (!context.mounted) {
                  return;
                }
                EasyLoading.showToast(lang.leavingSpaceSuccessful);
                for (final parentId in parentIds) {
                  ref.invalidate(spaceRelationsProvider(parentId));
                  ref.invalidate(spaceRemoteRelationsProvider(parentId));
                }
                Navigator.pop(context);
                context.goNamed(Routes.dashboard.name);
              } catch (e, s) {
                _log.severe('Failed to leave space', e, s);
                if (!context.mounted) {
                  EasyLoading.dismiss();
                  return;
                }
                EasyLoading.showError(
                  lang.leavingSpaceFailed(e),
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: Text(lang.yesLeave),
          ),
        ],
      );
    },
  );
}
