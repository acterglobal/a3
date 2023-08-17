import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/like_button.dart';
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
    final space = ref.watch(briefSpaceItemProvider(roomId));

    var bgColor = convertColor(
      news.colors()?.background(),
      Theme.of(context).colorScheme.neutral6,
    );
    var fgColor = convertColor(
      news.colors()?.color(),
      Theme.of(context).colorScheme.neutral6,
    );
    TextStyle style = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 13,
      color: fgColor,
      shadows: [
        Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        LikeButton(
          likeCount: news.likesCount().toString(),
          style: style,
          color: fgColor,
          index: index,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showCommentsBottomSheet(context),
          child: _SideBarItem(
            icon: const Icon(Atlas.comment_dots, color: Colors.white),
            label: news.commentsCount().toString(),
            style: style,
          ),
        ),
        _SideBarItem(
          icon: const Icon(Atlas.curve_arrow_right_bold, color: Colors.white),
          label: '76',
          style: style,
        ),
        GestureDetector(
          onTap: () => showReportBottomSheet(context),
          child: _SideBarItem(
            icon: const Icon(Atlas.dots_horizontal_thin),
            label: '',
            style: style,
          ),
        ),
        InkWell(
          onTap: () {
            context.goNamed(
              Routes.space.name,
              pathParameters: {'spaceId': roomId},
            );
          },
          child: space.when(
            data: (space) => ActerAvatar(
              uniqueId: roomId,
              mode: DisplayMode.Space,
              displayName: space!.spaceProfileData.displayName,
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
        const SizedBox(height: 8),
      ],
    );
  }

  void showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) {
        return SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Copy Link',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Bookmark/Save',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Get Notified',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Report this post',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void showCommentsBottomSheet(BuildContext context) {
    customMsgSnackbar(
      context,
      'Comment not yet implemented',
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
