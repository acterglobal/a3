import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/sheets/default_bottom_sheet.dart';
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
    final bgColor = convertColor(
      news.colors()?.background(),
      Theme.of(context).colorScheme.neutral6,
    );
    final fgColor = convertColor(
      news.colors()?.color(),
      Theme.of(context).colorScheme.neutral6,
    );
    final TextStyle? actionLabelStyle = Theme.of(context).textTheme.labelLarge;
    final TextStyle style = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 13,
      color: fgColor,
      shadows: [
        Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
      ],
    );
    final List<PopupMenuEntry> submenu = isDesktop
        ? [
            PopupMenuItem(
              onTap: () {},
              child: Text(
                'Report this post',
                style: actionLabelStyle!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ]
        : [];

    return Column(
      children: <Widget>[
        const Spacer(),
        LikeButton(
          likeCount: news.likesCount().toString(),
          style: style,
          color: fgColor,
          index: index,
        ),
        const SizedBox(height: 20),
        isDesktop
            ? PopupMenuButton(
                itemBuilder: (context) {
                  return submenu;
                },
                child: _SideBarItem(
                  icon: const Icon(Atlas.dots_horizontal_thin),
                  label: '',
                  style: style,
                ),
              )
            : InkWell(
                onTap: () => defaultBottomSheet(
                  context: context,
                  content:
                      _BottomSheetActions(actionLabelStyle: actionLabelStyle),
                  sheetHeight: 100.0,
                ),
                child: _SideBarItem(
                  icon: const Icon(Atlas.dots_horizontal_thin),
                  label: '',
                  style: style,
                ),
              ),
        const SizedBox(height: 10),
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

class _BottomSheetActions extends ConsumerWidget {
  final TextStyle? actionLabelStyle;
  const _BottomSheetActions({required this.actionLabelStyle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        GestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Report this Post',
              style: actionLabelStyle!
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
