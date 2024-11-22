import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

Future<void> showRoomPreview({
  required BuildContext context,
  required WidgetRef ref,
  required String roomIdOrAlias,
  List<String> serverNames = const [],
}) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        topLeft: Radius.circular(20),
      ),
    ),
    builder: (context) => _ShowRoomPreview(
      roomIdOrAlias: roomIdOrAlias,
      serverNames: serverNames,
    ),
  );
}

class _ShowRoomPreview extends ConsumerWidget {
  final String roomIdOrAlias;
  final List<String> serverNames;
  const _ShowRoomPreview({
    required this.roomIdOrAlias,
    required this.serverNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (
      roomIdOrAlias: roomIdOrAlias,
      serverNames: serverNames,
    );
    final roomPreview = ref.watch(roomPreviewProvider(query));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: roomPreview.when(
        data: (roomPreview) => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            roomHeader(context, ref, roomPreview),
            const SizedBox(height: 20),
            renderActions(context, ref),
          ],
        ),
        error: (error, stack) => ErrorPage(
          background: loading(),
          error: error,
          stack: stack,
          textBuilder: (error, errCode) => switch (errCode) {
            ErrorCode.forbidden =>
              L10n.of(context).accessDeniedToRoom(query.roomIdOrAlias),
            _ => L10n.of(context).loadingFailed(error)
          },
          onRetryTap: () => ref.invalidate(roomPreviewProvider(query)),
        ),
        loading: loading,
      ),
    );
  }

  Widget loading() => const Skeletonizer(
        child: Column(
          children: [Text('adbdc'), Text('adc')],
        ),
      );

  Widget roomHeader(BuildContext context, WidgetRef ref, preview) =>
      Text(preview.name() ?? preview.roomIdStr());

  Widget renderActions(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
