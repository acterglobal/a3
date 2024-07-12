import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zoom_hover_pinch_image/zoom_hover_pinch_image.dart';

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
    final membership = ref.watch(roomMembershipProvider(roomId)).requireValue;
    return AppBar(
      leading: IconButton(
        onPressed: context.pop,
        icon: const Icon(Icons.close),
      ),
      actions: [
        if (membership?.canString('CanUpdateAvatar') == true)
          IconButton(
            onPressed: () => uploadAvatar(ref, context, roomId),
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final profileData = ref.watch(roomAvatarInfoProvider(roomId));

    if (profileData.avatar == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Zoom(
        width: size.width,
        height: size.height,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fitWidth,
              image: profileData.avatar!,
            ),
          ),
        ),
      ),
    );
  }
}
