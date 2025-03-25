import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/space/actions/convert_into_acter_space.dart';
import 'package:acter/features/space/actions/set_space_topic.dart';
import 'package:acter/features/space/providers/topic_provider.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutSection extends ConsumerWidget {
  final String spaceId;

  const AboutSection({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutLabel(context),
              spaceDescription(context, ref),

              if (ref.watch(isActerSpace(spaceId)).valueOrNull != true &&
                  ref
                          .watch(
                            roomPermissionProvider((
                              roomId: spaceId,
                              permission: 'CanUpgradeToActerSpace',
                            )),
                          )
                          .valueOrNull ==
                      true)
                acterSpaceInfoUI(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget acterSpaceInfoUI(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 15),
    child: Tooltip(
      message: L10n.of(context).thisIsNotAProperActerSpace,
      child: OutlinedButton.icon(
        onPressed: () async {
          await convertIntoActerSpace(
            context: context,
            ref: ref,
            spaceId: spaceId,
          );
        },
        label: Text(L10n.of(context).upgradeToActerSpace),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        icon: const Icon(Atlas.up_arrow),
      ),
    ),
  );

  Widget aboutLabel(BuildContext context) {
    return Text(
      L10n.of(context).about,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget spaceDescription(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final topic = ref.watch(topicProvider(spaceId)).valueOrNull;
    Widget child = Text(
      topic ?? lang.noTopicFound,
      style: Theme.of(context).textTheme.bodySmall,
    );
    if (ref
            .watch(
              roomPermissionProvider((
                roomId: spaceId,
                permission: 'CanSetTopic',
              )),
            )
            .valueOrNull ==
        true) {
      child = GestureDetector(
        onTap: () async {
          showEditDescriptionBottomSheet(
            context: context,
            ref: ref,
            spaceId: spaceId,
          );
        },
        child: child,
      );
    }
    return SelectionArea(child: child);
  }
}
