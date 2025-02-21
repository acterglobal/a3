import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/actions/submit_news.dart';
import 'package:acter/features/news/actions/submit_story.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PostType { story, boost }

class AddNewsPostToPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;

  const AddNewsPostToPage({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<AddNewsPostToPage> createState() => _AddNewsPostToPageState();
}

class _AddNewsPostToPageState extends ConsumerState<AddNewsPostToPage> {
  PostType selectedOption = PostType.story;
  ValueNotifier<bool> canPostBoost = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final selectedSpaceId = ref.read(newsStateProvider).newsPostSpaceId;
    if (selectedSpaceId != null) {
      final membership =
          ref.watch(roomMembershipProvider(selectedSpaceId)).valueOrNull;
      canPostBoost.value = membership?.canString('CanPostNews') == true;
      if (canPostBoost.value == false) {
        selectedOption = PostType.story;
      }
    }
    return Scaffold(
      appBar: appBarUI(),
      body: postToBodyUI(),
    );
  }

  AppBar appBarUI() {
    final lang = L10n.of(context);
    return AppBar(title: Text(lang.postTo));
  }

  Widget postToBodyUI() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        spaceSelector(),
        SectionHeader(title: lang.select),
        postOptionItemUI(
          true,
          lang.story,
          lang.storyInfo,
          Icons.amp_stories,
          PostType.story,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: canPostBoost,
          builder: (context, canPostBoost, child) {
            return postOptionItemUI(
              canPostBoost,
              lang.boost,
              lang.boostInfo,
              Icons.rocket_launch_sharp,
              PostType.boost,
            );
          },
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.all(18),
          child: ActerPrimaryActionButton(
            onPressed: () => selectedOption == PostType.story
                ? sendStory(context, ref)
                : sendNews(context, ref),
            child: Text(lang.post.toUpperCase()),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget spaceSelector() {
    final newsPostSpaceId = ref.watch(newsStateProvider).newsPostSpaceId;

    final spaceSelectorWidget = (newsPostSpaceId != null)
        ? InkWell(
            key: UpdateKeys.selectSpace,
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
            key: UpdateKeys.selectSpace,
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

  Widget postOptionItemUI(
    bool isEnable,
    String title,
    String description,
    IconData iconData,
    PostType optionValue,
  ) {
    final color = !isEnable ? Theme.of(context).disabledColor : null;
    return InkWell(
      onTap: isEnable
          ? () {
              setState(() {
                selectedOption = optionValue;
              });
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(iconData, color: color),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color),
                  ),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Radio(
              value: optionValue,
              groupValue: selectedOption,
              onChanged: isEnable
                  ? (value) {
                      setState(() {
                        selectedOption = value as PostType;
                      });
                    }
                  : null,
              focusNode: FocusNode(),
              toggleable: isEnable,
            ),
          ],
        ),
      ),
    );
  }
}
