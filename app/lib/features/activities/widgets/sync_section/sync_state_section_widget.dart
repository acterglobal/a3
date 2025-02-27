import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSyncingStateSectionWidget(BuildContext context, WidgetRef ref) {
  final lang = L10n.of(context);
  final subTitleTextStyle = Theme.of(context).textTheme.labelMedium;
  final syncState = ref.watch(syncStateProvider);
  final String? errorMsg = syncState.errorMsg;
  final Duration? retryDuration = syncState.countDown.map(
    (countDown) => Duration(seconds: countDown),
  );

  if (!ref.watch(hasFirstSyncedProvider)) {
    return buildSyncingStateCard(lang, subTitleTextStyle);
  } else if (errorMsg != null) {
    return buildSyncingErrorStateCard(
      lang,
      errorMsg,
      retryDuration,
      subTitleTextStyle,
    );
  }

  return null;
}

Widget buildSyncingStateCard(L10n lang, TextStyle? subTitleTextStyle) {
  return Card(
    child: ListTile(
      leading: const Icon(Atlas.arrows_dots_rotate),
      title: Text(lang.renderSyncingTitle),
      subtitle: Text(lang.renderSyncingSubTitle, style: subTitleTextStyle),
    ),
  );
}

Widget buildSyncingErrorStateCard(
  L10n lang,
  String errorMsg,
  Duration? retryDuration,
  TextStyle? subTitleTextStyle,
) {
  return Card(
    child: ListTile(
      leading: Icon(Atlas.warning, color: warningColor),
      title: Text(lang.errorSyncing(errorMsg)),
      subtitle: Text(
        retryDuration == null
            ? lang.retrying
            : lang.retryIn(
              retryDuration.inMinutes.remainder(60).toString().padLeft(2, '0'),
              retryDuration.inSeconds.remainder(60).toString().padLeft(2, '0'),
            ),
        style: subTitleTextStyle,
      ),
    ),
  );
}
