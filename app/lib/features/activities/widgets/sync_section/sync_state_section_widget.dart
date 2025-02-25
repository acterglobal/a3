import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSyncingStateSectionWidget(BuildContext context, WidgetRef ref) {
  final lang = L10n.of(context);
  final syncState = ref.watch(syncStateProvider);
  final errorMsg = syncState.errorMsg;
  final retryDuration =
      syncState.countDown.map((countDown) => Duration(seconds: countDown));
  if (!ref.watch(hasFirstSyncedProvider)) {
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.arrows_dots_rotate),
        title: Text(lang.renderSyncingTitle),
        subtitle: Text(lang.renderSyncingSubTitle),
      ),
    );
  } else if (errorMsg != null) {
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.warning),
        title: Text(lang.errorSyncing(errorMsg)),
        subtitle: Text(
          retryDuration == null
              ? lang.retrying
              : lang.retryIn(
                  retryDuration.inMinutes
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0'),
                  retryDuration.inSeconds
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0'),
                ),
        ),
      ),
    );
  }
  return null;
}
