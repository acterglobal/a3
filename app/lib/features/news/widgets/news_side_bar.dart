import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_bottom_sheet.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

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
    final space = ref.watch(briefSpaceItemWithMembershipProvider(roomId));
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        const Spacer(),
        LikeButton(
          isLiked: isLikedByMe.valueOrNull ?? false,
          likeCount: likesCount.valueOrNull ?? 0,
          style: style,
          color: Colors.white,
          index: index,
          onTap: () async {
            final manager = await ref.watch(newsReactionsProvider(news).future);
            final status = manager.likedByMe();
            debugPrint('my like status: $status');
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
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) => DefaultBottomSheet(
                content: ActionBox(
                  news: news,
                  userId: userId,
                  roomId: roomId,
                  membership: space.membership!,
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
            onAvatarTap: () {
              context.pushNamed(
                Routes.space.name,
                pathParameters: {'spaceId': roomId},
              );
            },
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
  final ffi.Member membership;

  const ActionBox({
    super.key,
    required this.news,
    required this.userId,
    required this.roomId,
    required this.membership,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderId = news.sender().toString();
    final isAuthor = senderId == userId;
    List<Widget> actions = [const Text('Actions'), const Divider()];

    if (!isAuthor) {
      actions.add(
        TextButton.icon(
          onPressed: () => showAdaptiveDialog(
            context: context,
            builder: (context) => ReportContentWidget(
              title: 'Report this post',
              eventId: news.eventId().toString(),
              description:
                  'Report this post to your homeserver administrator. Please note that administrator would\'t be able to read or view any files in encrypted spaces.',
              senderId: senderId,
              roomId: roomId,
              isSpace: true,
            ),
          ),
          icon: const Icon(Atlas.exclamation_chat_thin),
          label: const Text('Report this'),
        ),
      );
    }

    if (isAuthor && membership.canString('CanRedactOwn')) {
      actions.add(
        TextButton.icon(
          onPressed: () => showAdaptiveDialog(
            context: context,
            builder: (context) => RedactContentWidget(
              title: 'Remove this post',
              eventId: news.eventId().toString(),
              onSuccess: () {
                context.pop();
                ref.invalidate(newsListProvider);
              },
              senderId: senderId,
              roomId: roomId,
              isSpace: true,
            ),
          ),
          icon: const Icon(Atlas.trash_thin),
          label: const Text('Remove'),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }
}
