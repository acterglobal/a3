import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          children: [
            actionButton(
              context: context,
              iconData: Atlas.pin,
              color: const Color(0xff7c4a4a),
              title: lang.addPin,
              onPressed: () => context.pushNamed(Routes.createPin.name),
            ),
            actionButton(
              context: context,
              iconData: Atlas.list,
              title: lang.addTask,
              color: const Color(0xff406c6e),
              onPressed: () => showCreateUpdateTaskListBottomSheet(context),
            ),
            actionButton(
              context: context,
              iconData: Atlas.calendar_dots,
              title: lang.addEvent,
              color: const Color(0xff206a9a),
              onPressed: () => context.pushNamed(Routes.createEvent.name),
            ),
            actionButton(
              context: context,
              iconData: Atlas.megaphone_thin,
              title: lang.addBoost,
              color: Colors.blueGrey,
              onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
            ),
          ],
        ),
        const SizedBox(height: 20 ),
      ],
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
      onPressed: () {
        Navigator.pop(context);
        onPressed();
      },
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).unselectedWidgetColor,
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: Icon(
          iconData,
          size: 16,
        ),
      ),
      label: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
