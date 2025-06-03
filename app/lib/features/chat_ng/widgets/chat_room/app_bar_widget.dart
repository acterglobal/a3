import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/display_name_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:ui';

final _log = Logger('a3::chat_ng::room::app_bar_widget');

class ChatRoomAppBarWidget extends ConsumerWidget
    implements PreferredSizeWidget {
  final String roomId;
  final VoidCallback? onProfileTap;

  const ChatRoomAppBarWidget({
    super.key,
    required this.roomId,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRect(
      child: Stack(
        children: [
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5), // Optional overlay
            ),
          ),
          // AppBar content
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                _buildRoomAvatar(context),
                Expanded(child: _buildRoomTitle(context, ref)),
              ],
            ),
            actions: _buildActions(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTitle(BuildContext context, WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    return GestureDetector(
      onTap: onProfileTap,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DisplayNameWidget(roomId: roomId),
          if (!isDM) _buildRoomMembersCount(context, ref),
        ],
      ),
    );
  }

  Widget _buildRoomMembersCount(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textStyle = Theme.of(context).textTheme.labelMedium;
    final membersLoader = ref.watch(membersIdsProvider(roomId));
    return membersLoader.when(
      data:
          (members) =>
              Text(lang.membersCount(members.length), style: textStyle),
      error: (e, s) {
        _log.severe('Failed to load active members', e, s);
        return Text(lang.errorLoadingMembersCount(e), style: textStyle);
      },
      loading: () => Skeletonizer(child: Text(lang.membersCount(100))),
    );
  }

  Widget _buildRoomAvatar(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: RoomAvatar(roomId: roomId, showParents: true),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull ?? false;
    return [
      if (!isEncrypted)
        IconButton(
          onPressed: () => EasyLoading.showInfo(lang.chatNotEncrypted),
          icon: Icon(
            PhosphorIcons.shieldWarning(),
            color: Theme.of(context).colorScheme.error,
          ),
        ),
    ];
  }
}
