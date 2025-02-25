import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/widgets/activity_section_item_widget.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter/features/settings/widgets/session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Widget? buildSessionsWidget(BuildContext context, WidgetRef ref) {
  final lang = L10n.of(context);
  final allSessions = ref.watch(unknownSessionsProvider);
  final err = allSessions.error;
  if (err != null) {
    return Text(lang.errorUnverifiedSessions(err.toString()));
  }
  return allSessions.value.map((val) {
    final sessions = val.where((session) => !session.isVerified()).toList();
    if (sessions.isEmpty) return null;
    if (sessions.length == 1) return SessionCard(deviceRecord: sessions[0]);

    return ActivitySectionItemWidget(
      icon: Icons.warning_amber_rounded,
      iconColor: warningColor,
      title: lang.unverifiedSessionsTitle(sessions.length),
      subtitle: '',
      actions: [
        OutlinedButton(
          onPressed: () {
            context.pushNamed(Routes.settingSessions.name);
          },
          child: Text(lang.review),
        ),
      ],
    );
  });
}
