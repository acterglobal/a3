import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/action_button_widget.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickActionButtons extends ConsumerWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            children: [
              ActionButtonWidget(
                iconData: Atlas.pin,
                color: const Color(0xff7c4a4a),
                title: lang.addPin,
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  context.pushNamed(Routes.createPin.name);
                },
              ),
              ActionButtonWidget(
                iconData: Atlas.list,
                title: lang.addTaskList,
                color: const Color(0xff406c6e),
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  showCreateUpdateTaskListBottomSheet(context);
                },
              ),
              ActionButtonWidget(
                iconData: Atlas.calendar_dots,
                title: lang.addEvent,
                color: const Color(0xff206a9a),
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  context.pushNamed(Routes.createEvent.name);
                },
              ),
              ActionButtonWidget(
                iconData: Atlas.megaphone_thin,
                title: lang.addBoost,
                color: Colors.blueGrey,
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  context.pushNamed(Routes.actionAddUpdate.name);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
