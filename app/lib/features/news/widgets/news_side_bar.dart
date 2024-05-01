import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_bottom_sheet.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::news::sidebar');

class NewsSideBar extends ConsumerWidget {
  final ffi.NewsEntry news;
  final int index;

  const NewsSideBar({
    super.key,
    required this.news,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = news.roomId().toString();
    final userId = ref.watch(myUserIdStrProvider);
    final isLikedByMe = ref.watch(likedByMeProvider(news));
    final likesCount = ref.watch(totalLikesForNewsProvider(news));
    final space = ref.watch(briefSpaceItemProvider(roomId));
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        const Spacer(),
        LikeButton(
          isLiked: isLikedByMe.valueOrNull ?? false,
          likeCount: likesCount.valueOrNull ?? 0,
          style: style,
          color: Theme.of(context).colorScheme.textColor,
          index: index,
          onTap: () async {
            final manager = await ref.read(newsReactionsProvider(news).future);
            final status = manager.likedByMe();
            _log.info('my like status: $status');
            if (!status) {
              await manager.sendLike();
            } else {
              await manager.redactLike(null, null);
            }
          },
        ),
        const SizedBox(height: 10),
        space.maybeWhen(
          data: (space) => InkWell(
            key: NewsUpdateKeys.newsSidebarActionBottomSheet,
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) => DefaultBottomSheet(
                content: ActionBox(
                  news: news,
                  userId: userId,
                  roomId: roomId,
                ),
              ),
            ),
            child: _SideBarItem(
              icon: const Icon(Atlas.dots_horizontal_thin),
              label: '',
              style: style,
            ),
          ),
          orElse: () => _SideBarItem(
            icon: const Icon(Atlas.dots_horizontal_thin),
            label: '',
            style: style,
          ),
        ),
        const SizedBox(height: 10),
        space.when(
          data: (space) => ActerAvatar(
            mode: DisplayMode.Space,
            avatarInfo: AvatarInfo(
              uniqueId: roomId,
              displayName: space.spaceProfileData.displayName,
              avatar: space.spaceProfileData.getAvatarImage(),
            ),
            size: 42,
            onAvatarTap: () => goToSpace(context, roomId),
          ),
          error: (e, st) {
            _log.severe('Error loading space', e, st);
            return ActerAvatar(
              mode: DisplayMode.Space,
              avatarInfo: AvatarInfo(
                uniqueId: roomId,
                displayName: roomId,
              ),
              size: 42,
            );
          },
          loading: () => Skeletonizer(
            child: ActerAvatar(
              mode: DisplayMode.Space,
              avatarInfo: AvatarInfo(uniqueId: roomId),
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

class _SideBarItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final TextStyle style;

  const _SideBarItem({
    required this.icon,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon,
        const SizedBox(height: 5),
        Text(label, style: style),
      ],
    );
  }
}

class ActionBox extends ConsumerWidget {
  final String userId;
  final ffi.NewsEntry news;
  final String roomId;

  const ActionBox({
    super.key,
    required this.news,
    required this.userId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderId = news.sender().toString();
    final membership = ref.watch(roomMembershipProvider(roomId)).valueOrNull;
    final isAuthor = senderId == userId;
    List<Widget> actions = [
      Text(L10n.of(context).actions),
      const Divider(),
    ];

    if (!isAuthor) {
      actions.add(
        TextButton.icon(
          key: NewsUpdateKeys.newsSidebarActionReportBtn,
          onPressed: () => showAdaptiveDialog(
            context: context,
            builder: (context) => ReportContentWidget(
              title: L10n.of(context).reportThisPost,
              eventId: news.eventId().toString(),
              description: L10n.of(context).reportPostContent,
              senderId: senderId,
              roomId: roomId,
              isSpace: true,
            ),
          ),
          icon: const Icon(Atlas.exclamation_chat_thin),
          label: Text(L10n.of(context).reportThis),
        ),
      );
    }

    if (isAuthor &&
        membership != null &&
        membership.canString('CanRedactOwn')) {
      actions.add(
        TextButton.icon(
          key: NewsUpdateKeys.newsSidebarActionRemoveBtn,
          onPressed: () => showAdaptiveDialog(
            context: context,
            builder: (context) => RedactContentWidget(
              title: L10n.of(context).removeThisPost,
              eventId: news.eventId().toString(),
              onSuccess: () {
                context.pop();
                ref.invalidate(newsListProvider);
              },
              senderId: senderId,
              roomId: roomId,
              isSpace: true,
              removeBtnKey: NewsUpdateKeys.removeButton,
            ),
          ),
          icon: const Icon(Atlas.trash_thin),
          label: Text(L10n.of(context).remove),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }
}
