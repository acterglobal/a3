import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final bool isDesktop =
        desktopPlatforms.contains(Theme.of(context).platform);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MediaQuery.of(context).size.width < 600
            ? !client.isGuest()
                ? Container(
                    margin: const EdgeInsets.only(left: 8, top: 5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.neutral6,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const UserAvatarWidget(),
                  )
                : GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: TextAvatar(
                            backgroundColor: Colors.grey,
                            text: 'G',
                            numberLetters: 1,
                            shape: Shape.Circular,
                            upperCase: true,
                          ),
                        ),
                      ],
                    ),
                  )
            : const SizedBox.shrink(),
        centerTitle: true,
        actions: <Widget>[
          Visibility(
            visible: !isDesktop,
            child: IconButton(
              onPressed: () => context.go('/updates/post_edit'),
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
                size: 36,
              ),
            ),
          ),
        ],
      ),
      body: const NewsWidget(),
    );
  }
}
