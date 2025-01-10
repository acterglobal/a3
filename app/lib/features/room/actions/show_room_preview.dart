import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

Future<void> showRoomPreview({
  required BuildContext context,
  required String roomIdOrAlias,
  Widget? headerInfo,
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
      headerInfo: headerInfo,
      serverNames: serverNames,
    ),
  );
}

class _ShowRoomPreview extends ConsumerWidget {
  final String roomIdOrAlias;
  final List<String> serverNames;
  final Widget? headerInfo;
  const _ShowRoomPreview({
    required this.roomIdOrAlias,
    required this.serverNames,
    this.headerInfo,
  });

  RoomPreviewQuery get query => (
        roomIdOrAlias: roomIdOrAlias,
        serverNames: AllHashed(serverNames),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomPreview = ref.watch(roomPreviewProvider(query));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: roomPreview.when(
        data: (roomPreview) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (headerInfo != null) headerInfo!,
            roomHeader(roomPreview),
            roomInfo(context, roomPreview),
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

  Widget roomHeader(RoomPreview preview) => Consumer(
        builder: (context, ref, child) => ListTile(
          leading: ActerAvatar(
            options: AvatarOptions(ref.watch(roomPreviewAvatarInfo(query))),
          ),
          title: Text(
            preview.name() ?? preview.roomIdStr(),
          ),
          subtitle: Text(preview.canonicalAliasStr() ?? ''),
        ),
      );

  Widget roomInfo(BuildContext context, RoomPreview preview) {
    final description = preview.topic();
    if (description == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).about,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget renderActions(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
