import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/edit_plain_description_sheet.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
            ],
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
    final space = ref.watch(spaceProvider(spaceId));
    return space.when(
      data: (space) {
        final topic = space.topic();
        return SelectionArea(
          child: GestureDetector(
            onTap: () async {
              if (await editDescriptionPermissionCheck(ref) &&
                  context.mounted) {
                showEditDescriptionBottomSheet(
                  context: context,
                  space: space,
                  descriptionValue: topic ?? '',
                );
              }
            },
            child: Text(
              topic ?? L10n.of(context).noTopicFound,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
      error: (error, stack) => Text(
        L10n.of(context).loadingFailed(error),
      ),
      loading: () => Skeletonizer(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  // permission check
  Future<bool> editDescriptionPermissionCheck(WidgetRef ref) async {
    final space = await ref.read(spaceProvider(spaceId).future);
    final membership = await space.getMyMembership();
    return membership.canString('CanSetTopic');
  }

  void showEditDescriptionBottomSheet({
    required BuildContext context,
    required Space space,
    required String descriptionValue,
  }) {
    showEditPlainDescriptionBottomSheet(
      context: context,
      descriptionValue: descriptionValue,
      onSave: (newDescription) async {
        try {
          EasyLoading.show(status: L10n.of(context).updateDescription);
          await space.setTopic(newDescription);
          EasyLoading.dismiss();
          if (!context.mounted) return;
          context.pop();
        } catch (e) {
          EasyLoading.dismiss();
          if (!context.mounted) return;
          EasyLoading.showError(L10n.of(context).updateDescriptionFailed(e));
        }
      },
    );
  }
}
