import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::spaces::select_form_field');

class SelectSpaceFormField extends ConsumerWidget {
  static Key openKey = const Key('select-space-form-field-open');

  final String? title;
  final String? selectTitle;
  final String? emptyText;
  final String canCheck;
  final bool mandatory;
  final bool useCompatView;

  const SelectSpaceFormField({
    super.key,
    this.title,
    this.selectTitle,
    this.emptyText,
    this.mandatory = true,
    required this.canCheck,
    this.useCompatView = false,
  });

  void selectSpace(BuildContext context, WidgetRef ref) async {
    final newSelectedSpaceId = await selectSpaceDrawer(
      context: context,
      currentSpaceId: ref.read(selectedSpaceIdProvider),
      canCheck: canCheck,
      title: Text(selectTitle ?? L10n.of(context).selectSpace),
    );
    ref.read(selectedSpaceIdProvider.notifier).state = newSelectedSpaceId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSelectedSpace = ref.watch(selectedSpaceIdProvider);
    final selectedSpace = currentSelectedSpace != null;

    final emptyButton = OutlinedButton(
      key: openKey,
      onPressed: () => selectSpace(context, ref),
      child: Text(emptyText ?? L10n.of(context).pleaseSelectSpace),
    );

    return FormField(
      builder: (state) => selectedSpace
          ? InkWell(
              key: openKey,
              onTap: () => selectSpace(context, ref),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!useCompatView)
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
                          state.errorText ?? '',
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
    final spaceLoader = ref.watch(selectedSpaceDetailsProvider);
    final currentId = ref.watch(selectedSpaceIdProvider);
    return spaceLoader.when(
      data: (space) =>
          space.map(
            (p0) => SpaceChip(
              spaceId: p0.roomId,
              onTapOpenSpaceDetail: false,
              useCompatView: useCompatView,
              onTapSelectSpace: () {
                if (useCompatView) selectSpace(context, ref);
              },
            ),
          ) ??
          Text(currentId!),
      error: (e, s) {
        _log.severe('Failed to load the details of selected space', e, s);
        return Text(L10n.of(context).loadingFailed(e));
      },
      loading: () => Skeletonizer(
        child: Chip(
          avatar: ActerAvatar(
            options: AvatarOptions(
              AvatarInfo(uniqueId: L10n.of(context).loading),
              size: 24,
            ),
          ),
          label: Text(L10n.of(context).loading),
        ),
      ),
    );
  }
}
