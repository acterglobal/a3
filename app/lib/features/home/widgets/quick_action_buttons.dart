import 'dart:io';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/action_button_widget.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:acter/features/tasks/actions/create_task.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickActionButtons extends ConsumerWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(children: quickActions(context, ref)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(PhosphorIconsThin.question),
                onPressed: () {
                  ref.read(quickActionVisibilityProvider.notifier).state =
                      false;
                  launchUrl(Uri.parse(Env.helpCenterUrl));
                },
              ),
              if (isBugReportingEnabled)
                ActerInlineTextButton(
                  onPressed: () {
                    ref.read(quickActionVisibilityProvider.notifier).state =
                        false;
                    openBugReport(context);
                  },
                  child: const Text('Bug Report'),
                ),
              if (Platform.isAndroid ||
                  Platform.isIOS) // only accessible on mobile
                IconButton(
                  onPressed: () {
                    ref.read(quickActionVisibilityProvider.notifier).state =
                        false;
                    context.pushNamed(Routes.scanQrCode.name);
                  },
                  icon: const Icon(PhosphorIconsThin.qrCode),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  List<Widget> quickActions(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final canAddPin =
        ref.watch(hasSpaceWithPermissionProvider('CanPostPin')).valueOrNull ??
        false;
    final canAddEvent =
        ref.watch(hasSpaceWithPermissionProvider('CanPostEvent')).valueOrNull ??
        false;
    final canAddTask =
        ref.watch(hasSpaceWithPermissionProvider('CanPostTask')).valueOrNull ??
        false;
    final canAddBoost =
        ref.watch(hasSpaceWithPermissionProvider('CanPostNews')).valueOrNull ??
        false;
    return [
      ActionButtonWidget(
        iconData: Atlas.users,
        title: lang.createSpace,
        color: Colors.purpleAccent.withAlpha(70),
        padding: const EdgeInsets.symmetric(vertical: 6),
        onPressed: () {
          ref.read(quickActionVisibilityProvider.notifier).state = false;
          context.pushNamed(Routes.createSpace.name);
        },
      ),
      ActionButtonWidget(
        iconData: Atlas.chats,
        title: lang.createChat,
        color: Colors.green.withAlpha(70),
        padding: const EdgeInsets.symmetric(vertical: 6),
        onPressed: () {
          ref.read(quickActionVisibilityProvider.notifier).state = false;
          context.pushNamed(Routes.createChat.name);
        },
      ),
      if (canAddPin)
        ActionButtonWidget(
          iconData: Atlas.pin,
          color: pinFeatureColor,
          title: lang.addPin,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            context.pushNamed(Routes.createPin.name);
          },
        ),
      if (canAddTask)
        ActionButtonWidget(
          iconData: Atlas.list,
          title: lang.addTask,
          color: taskFeatureColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            showCreateTaskBottomSheet(context);
          },
        ),
      if (canAddEvent)
        ActionButtonWidget(
          iconData: Atlas.calendar_dots,
          title: lang.addEvent,
          color: eventFeatureColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            context.pushNamed(Routes.createEvent.name);
          },
        ),
      if (canAddBoost)
        ActionButtonWidget(
          iconData: Atlas.megaphone_thin,
          title: lang.addBoost,
          color: boastFeatureColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            context.pushNamed(Routes.actionAddUpdate.name);
          },
        ),
    ];
  }
}
