import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/actions/set_space_topic.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::sections::about');

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
            children: [aboutLabel(context), spaceDescription(context, ref)],
          ),
        ),
      ),
    );
  }

  Widget aboutLabel(BuildContext context) {
    return Text(
      L10n.of(context).about,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget spaceDescription(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final spaceLoader = ref.watch(spaceProvider(spaceId));
    return spaceLoader.when(
      data: (space) {
        final topic = space.topic();
        return SelectionArea(
          child: GestureDetector(
            onTap: () async {
              final permitted = await editDescriptionPermissionCheck(ref);
              if (permitted && context.mounted) {
                showEditDescriptionBottomSheet(
                  context: context,
                  ref: ref,
                  spaceId: spaceId,
                );
              }
            },
            child: Text(
              topic ?? lang.noTopicFound,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
      error: (e, s) {
        _log.severe('Failed to load space', e, s);
        return Text(lang.failedToLoadSpace(e));
      },
      loading: () => Skeletonizer(child: Text(lang.loading)),
    );
  }

  // permission check
  Future<bool> editDescriptionPermissionCheck(WidgetRef ref) async {
    final space = await ref.read(spaceProvider(spaceId).future);
    final membership = await space.getMyMembership();
    return membership.canString('CanSetTopic');
  }
}
