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

class AddNewsPostToPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;

  const AddNewsPostToPage({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<AddNewsPostToPage> createState() => _AddNewsPostToPageState();
}

class _AddNewsPostToPageState extends ConsumerState<AddNewsPostToPage> {
  int selectedOption = 1;
  ValueNotifier<bool> canPostBoost = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
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
          'Stories',
          'Everyone can see, this is from you. It disappears in 14 days',
          Icons.amp_stories,
          1,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: canPostBoost,
          builder: (context, canPostBoost, child) {
            return postOptionItemUI(
              canPostBoost,
              'Boost',
              'Important News. Sends a push notification to 17 members',
              Icons.rocket_launch_sharp,
              2,
            );
          },
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.all(18),
          child: ActerPrimaryActionButton(
            onPressed: () => sendNews(context, ref),
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

  Widget postOptionItemUI(
    bool isEnable,
    String title,
    String description,
    IconData iconData,
    int optionValue,
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
                        selectedOption = optionValue;
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
