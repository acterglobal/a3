import 'package:acter/common/utils/routes.dart';
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
              actionButton(
                context: context,
                iconData: Atlas.pin,
                color: const Color(0xff7c4a4a),
                title: lang.addPin,
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  context.pushNamed(Routes.createPin.name);
                },
              ),
              actionButton(
                context: context,
                iconData: Atlas.list,
                title: lang.addTaskList,
                color: const Color(0xff406c6e),
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  showCreateUpdateTaskListBottomSheet(context);
                },
              ),
              actionButton(
                context: context,
                iconData: Atlas.calendar_dots,
                title: lang.addEvent,
                color: const Color(0xff206a9a),
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  context.pushNamed(Routes.createEvent.name);
                },
              ),
              actionButton(
                context: context,
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

  Widget actionButton({
    required BuildContext context,
    required IconData iconData,
    required String title,
    required VoidCallback onPressed,
    Color? color,
    Key? key,
  }) {
    return TextButton.icon(
      key: key,
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).unselectedWidgetColor,
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: Icon(iconData, size: 14),
      ),
      label: Text(title),
    );
  }
}
