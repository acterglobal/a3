import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/actions/submit_news.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddNewsPostToPage extends ConsumerWidget {
  final String? initialSelectedSpace;

  const AddNewsPostToPage({super.key, this.initialSelectedSpace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBarUI(context),
      body: postToBodyUI(context, ref),
    );
  }

  AppBar appBarUI(BuildContext context) {
    final lang = L10n.of(context);
    return AppBar(title: Text(lang.postTo));
  }

  Widget postToBodyUI(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: lang.space),
        spaceSelector(context, ref),
        SectionHeader(title: lang.select),
        Spacer(),
        ActerPrimaryActionButton(
          onPressed: () => sendNews(context, ref),
          child: Text(lang.post.toUpperCase()),
        ),
      ],
    );
  }

  Widget spaceSelector(BuildContext context, WidgetRef ref) {
    final newsPostSpaceId = ref.watch(newsStateProvider).newsPostSpaceId;

    final spaceSelectorWidget = (newsPostSpaceId != null)
        ? InkWell(
            key: NewsUpdateKeys.selectSpace,
            onTap: () async {
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.changeNewsPostSpaceId(context);
            },
            child: Row(
              children: [
                RoomAvatarBuilder(roomId: newsPostSpaceId, avatarSize: 42),
                SizedBox(width: 16),
                SpaceNameWidget(
                  spaceId: newsPostSpaceId,
                  isShowBrackets: false,
                ),
              ],
            ),
          )
        : OutlinedButton(
            key: NewsUpdateKeys.selectSpace,
            onPressed: () async {
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.changeNewsPostSpaceId(context);
            },
            child: Text(L10n.of(context).selectSpace),
          );

    return Padding(
      padding: const EdgeInsets.all(18),
      child: spaceSelectorWidget,
    );
  }
}
