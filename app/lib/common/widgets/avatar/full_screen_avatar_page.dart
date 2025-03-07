import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/actions/avatar_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinch_zoom_release_unzoom/pinch_zoom_release_unzoom.dart';

class FullScreenAvatarPage extends ConsumerWidget {
  final String roomId;

  const FullScreenAvatarPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: _buildBody(context, ref),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(roomId)).valueOrNull;
    return AppBar(
      leading: IconButton(
        onPressed: context.pop,
        icon: const Icon(Icons.close),
      ),
      actions: [
        if (membership?.canString('CanUpdateAvatar') == true)
          IconButton(
            onPressed: () => uploadAvatar(ref, context, roomId),
            icon: const Icon(Icons.upload),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(roomAvatarInfoProvider(roomId));
    return profileData.avatar.map(
          (data) => Center(
            child: PinchZoomReleaseUnzoomWidget(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(fit: BoxFit.fitWidth, image: data),
                ),
              ),
            ),
          ),
        ) ??
        const SizedBox.shrink();
  }
}
