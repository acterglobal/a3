import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/select_room_drawer.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectSpaceFormField extends ConsumerWidget {
  static Key openKey = const Key('select-space-form-field-open');

  final String? title;
  final String? selectTitle;
  final String? emptyText;
  final RoomCanCheck? canCheck;
  final bool mandatory;
  final bool useCompactView;
  final void Function(String? spaceId)? onSpaceSelected;

  const SelectSpaceFormField({
    super.key,
    this.title,
    this.selectTitle,
    this.emptyText,
    this.mandatory = true,
    this.canCheck,
    this.useCompactView = false,
    this.onSpaceSelected,
  });

  void selectSpace(BuildContext context, WidgetRef ref) async {
    final newSelectedSpaceId = await selectSpaceDrawer(
      context: context,
      currentSpaceId: ref.read(selectedSpaceIdProvider),
      canCheck: canCheck,
      title: Text(selectTitle ?? L10n.of(context).selectSpace),
    );
    ref.read(selectedSpaceIdProvider.notifier).state = newSelectedSpaceId;
    if (onSpaceSelected != null) {
      onSpaceSelected!(newSelectedSpaceId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSpaceId = ref.watch(selectedSpaceIdProvider);
    final lang = L10n.of(context);

    final emptyButton = OutlinedButton(
      key: openKey,
      onPressed: () => selectSpace(context, ref),
      child: Text(emptyText ?? lang.pleaseSelectSpace),
    );

    return FormField(
      builder:
          (state) =>
              currentSpaceId != null
                  ? InkWell(
                    key: openKey,
                    onTap: () => selectSpace(context, ref),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!useCompactView)
                          Text(
                            title ?? lang.space,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        Consumer(
                          builder: (context, ref, child) {
                            return spaceBuilder(
                              context,
                              ref,
                              child,
                              currentSpaceId,
                            );
                          },
                        ),
                      ],
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child:
                        state.errorText.map(
                          (err) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              emptyButton,
                              Text(
                                err,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        emptyButton,
                  ),
      validator:
          (val) =>
              !mandatory || ref.read(selectedSpaceIdProvider) != null
                  ? null
                  : lang.youMustSelectSpace,
    );
  }

  Widget spaceBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
    String currentSpaceId,
  ) {
    final space = ref.watch(selectedSpaceDetailsProvider);
    return space.map(
          (p0) => SpaceChip(
            spaceId: p0.roomId,
            onTapOpenSpaceDetail: false,
            useCompactView: useCompactView,
            onTapSelectSpace: () {
              selectSpace(context, ref);
            },
          ),
        ) ??
        Text(currentSpaceId);
  }
}
