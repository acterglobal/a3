import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SelectSpaceFormField extends ConsumerWidget {
  static Key openKey = const Key('select-space-form-field-open');

  final String? title;
  final String? selectTitle;
  final String? emptyText;
  final String canCheck;
  final bool mandatory;

  const SelectSpaceFormField({
    super.key,
    this.title,
    this.selectTitle,
    this.emptyText,
    this.mandatory = true,
    required this.canCheck,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSelectedSpace = ref.watch(selectedSpaceIdProvider);
    final spaceNotifier = ref.watch(selectedSpaceIdProvider.notifier);
    final selectedSpace = currentSelectedSpace != null;

    void selectSpace() async {
      final newSelectedSpaceId = await selectSpaceDrawer(
        context: context,
        currentSpaceId: ref.read(selectedSpaceIdProvider),
        canCheck: canCheck,
        title: Text(selectTitle ?? L10n.of(context).selectSpace),
      );
      spaceNotifier.state = newSelectedSpaceId;
    }

    final emptyButton = OutlinedButton(
      key: openKey,
      onPressed: selectSpace,
      child: Text(emptyText ?? L10n.of(context).pleaseSelectSpace),
    );

    return FormField(
      builder: (state) => selectedSpace
          ? InkWell(
              key: openKey,
              onTap: selectSpace,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? L10n.of(context).space,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Consumer(builder: spaceBuilder),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: state.hasError
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        emptyButton,
                        Text(
                          state.errorText!,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ],
                    )
                  : emptyButton,
            ),
      validator: (x) =>
          (!mandatory || ref.read(selectedSpaceIdProvider) != null)
              ? null
              : L10n.of(context).youMustSelectSpace,
    );
  }

  Widget spaceBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final spaceDetails = ref.watch(selectedSpaceDetailsProvider);
    final currentSelectedSpace = ref.watch(selectedSpaceIdProvider);
    return spaceDetails.when(
      data: (space) => space != null
          ? SpaceChip(
              space: space,
              onTapOpenSpaceDetail: false,
            )
          : Text(currentSelectedSpace!),
      error: (e, s) => Text(L10n.of(context).errorLoading(e)),
      loading: () => Skeletonizer(
        child: Chip(
          avatar: ActerAvatar(
            mode: DisplayMode.Space,
            avatarInfo: AvatarInfo(
              uniqueId: L10n.of(context).loading,
            ),
            size: 24,
          ),
          label: Text(L10n.of(context).loading),
        ),
      ),
    );
  }
}
