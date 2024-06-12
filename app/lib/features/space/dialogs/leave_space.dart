import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::spaces::leave_space');

const leaveSpaceYesBtn = Key('leave-space-yes-btn');

void showLeaveSpaceDialog(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) {
  showAdaptiveDialog(
    barrierDismissible: true,
    context: context,
    useRootNavigator: true,
    builder: (context) => DefaultDialog(
      title: Column(
        children: <Widget>[
          const Icon(Icons.person_remove_outlined),
          const SizedBox(height: 5),
          Text(
            L10n.of(context).leaveSpace,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      subtitle: Text(
        L10n.of(context).areYouSureYouWantToLeaveSpace,
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => context.pop(),
          child: Text(L10n.of(context).noIStay),
        ),
        ActerDangerActionButton(
          key: leaveSpaceYesBtn,
          onPressed: () async {
            final lang = L10n.of(context);
            try {
              EasyLoading.show(status: lang.leavingSpace);
              final space = await ref.read(spaceProvider(spaceId).future);
              await space.leave();
              // refresh spaces list
              ref.invalidate(spacesProvider);
              if (!context.mounted) {
                return;
              }
              EasyLoading.showToast(lang.leavingSpaceSuccessful);
              context.pop();
              context.goNamed(Routes.dashboard.name);
            } catch (error, stack) {
              _log.severe('Error leaving space', error, stack);
              EasyLoading.showError(lang.leavingSpaceFailed(error));
            }
          },
          child: Text(L10n.of(context).yesLeave),
        ),
      ],
    ),
  );
}
