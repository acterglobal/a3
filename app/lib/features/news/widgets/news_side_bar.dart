import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_bottom_sheet.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final userId = ref.watch(clientProvider)!.userId().toString();
    final space = ref.watch(briefSpaceItemWithMembershipProvider(roomId));
    final bgColor = convertColor(
      news.colors()?.background(),
      Theme.of(context).colorScheme.neutral6,
    );
    final fgColor = convertColor(
      news.colors()?.color(),
      Theme.of(context).colorScheme.neutral6,
    );
    final TextStyle style = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 13,
      color: fgColor,
      shadows: [
        Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
      ],
    );

    return Column(
      children: <Widget>[
        const Spacer(),
        LikeButton(
          likeCount: news.likesCount().toString(),
          style: style,
          color: fgColor,
          index: index,
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
        InkWell(
          onTap: () {
            context.pushNamed(
              Routes.space.name,
              pathParameters: {'spaceId': roomId},
            );
          },
          child: space.when(
            data: (space) => ActerAvatar(
              uniqueId: roomId,
              mode: DisplayMode.Space,
              displayName: space.spaceProfileData.displayName,
              avatar: space.spaceProfileData.getAvatarImage(),
              size: 42,
            ),
            error: (e, st) {
              debugPrint('Error loading space: $e');
              return ActerAvatar(
                uniqueId: roomId,
                mode: DisplayMode.Space,
                displayName: roomId,
                size: 42,
              );
            },
            loading: () => const Text('l'),
          ),
        ),
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

    if (!isAuthor || membership.canString('CanRedact')) {
      actions.add(
        TextButton.icon(
          onPressed: () => showAdaptiveDialog(
            context: context,
            builder: (context) => RedactContentWidget(
              title: 'Redact this post',
              eventId: news.eventId().toString(),
              onSuccess: () {
                ref.invalidate(newsListProvider);
              },
              senderId: senderId,
              roomId: roomId,
              isSpace: true,
            ),
          ),
          icon: const Icon(Atlas.trash_thin),
          label: const Text('Redact'),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }
}
