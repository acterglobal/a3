import 'package:acter/common/utils/routes.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final helpUrl = Uri.tryParse(Env.helpCenterUrl);
    final lang = L10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang.quickActions,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        searchWidget(context),
        Divider(
          endIndent: 0,
          indent: 0,
          color: Theme.of(context).unselectedWidgetColor,
        ),
        Wrap(
          children: [
            actionButton(
              context: context,
              iconData: Atlas.megaphone_thin,
              title: lang.addBoost,
              onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
            ),
            actionButton(
              context: context,
              iconData: Atlas.pin,
              title: lang.addPin,
              onPressed: () => context.pushNamed(Routes.createPin.name),
            ),
            actionButton(
              context: context,
              iconData: Atlas.list,
              title: lang.addTask,
              onPressed: () => showCreateUpdateTaskListBottomSheet(context),
            ),
            actionButton(
              context: context,
              iconData: Atlas.calendar_dots,
              title: lang.addEvent,
              onPressed: () => context.pushNamed(Routes.createEvent.name),
            ),
            actionButton(
              context: context,
              iconData: Atlas.chats,
              title: lang.addChat,
              onPressed: () => context.pushNamed(Routes.createChat.name),
            ),
            actionButton(
              context: context,
              iconData: Icons.people,
              title: lang.addSpace,
              onPressed: () => context.pushNamed(Routes.createSpace.name),
            ),
          ],
        ),
        Divider(
          endIndent: 0,
          indent: 0,
          color: Theme.of(context).unselectedWidgetColor,
        ),
        Wrap(
          children: [
            actionButton(
              context: context,
              iconData: Atlas.account,
              title: lang.profile,
              onPressed: () => context.pushNamed(Routes.myProfile.name),
            ),
            if (helpUrl != null)
              actionButton(
                context: context,
                iconData: Atlas.info_chat,
                title: lang.helpCenterTitle,
                onPressed: () => launchUrl(helpUrl),
              ),
            actionButton(
              context: context,
              iconData: Atlas.warning,
              title: lang.report,
              onPressed: () => openBugReport(context),
            ),
          ],
        ),
        const SizedBox(height: 50),
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

  Widget searchWidget(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.goNamed(Routes.search.name);
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).unselectedWidgetColor,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Text(L10n.of(context).search),
          ],
        ),
      ),
    );
  }
}
