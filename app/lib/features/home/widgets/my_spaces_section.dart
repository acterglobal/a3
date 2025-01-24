import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/spaces/widgets/space_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MySpacesSection extends ConsumerWidget {
  final int? limit;

  const MySpacesSection({
    super.key,
    this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Common variable declaration
    final lang = L10n.of(context);

    //Get spaces List Data
    final allSpacesList = ref.watch(spacesProvider);
    final bookmarkedSpacesList = ref.watch(bookmarkedSpacesProvider);

    //Empty State
    if (allSpacesList.isEmpty) return const _NoSpacesWidget();

    //Bookmarked Spaces : If available
    if (bookmarkedSpacesList.isNotEmpty) {
      return SpaceListWidget(
        spaceListProvider: bookmarkedSpacesProvider,
        showSectionHeader: true,
        isShowSeeAllButton: true,
        showSectionBg: false,
        showBookmarkedIndicator: false,
        sectionHeaderTitle: lang.bookmarkedSpaces,
        onClickSectionHeader: () => context.pushNamed(Routes.spaces.name),
      );
    }

    //All Spaces : If bookmark list is empty
    final count = limit.map((val) => min(val, allSpacesList.length)) ??
        allSpacesList.length;
    return SpaceListWidget(
      spaceListProvider: spacesProvider,
      showSectionHeader: true,
      sectionHeaderTitle: lang.mySpaces,
      limit: limit,
      showSectionBg: false,
      isShowSeeAllButton: count != allSpacesList.length,
      onClickSectionHeader: () => context.pushNamed(Routes.spaces.name),
    );
  }
}

class _NoSpacesWidget extends ConsumerStatefulWidget {
  const _NoSpacesWidget();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NoSpacesWidgetState();
}

class _NoSpacesWidgetState extends ConsumerState<_NoSpacesWidget> {
  @override
  void initState() {
    super.initState();
    if (!isDesktop) createOrJoinSpaceTutorials(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          lang.youAreCurrentlyNotConnectedToAnySpaces,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          lang.spaceShortDescription,
          style: textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        OutlinedButton.icon(
          key: createNewSpaceKey,
          onPressed: () => context.pushNamed(Routes.createSpace.name),
          label: Text(lang.createNewSpace),
        ),
        const SizedBox(height: 16),
        ActerPrimaryActionButton(
          key: joinExistingSpaceKey,
          onPressed: () {
            context.pushNamed(Routes.searchPublicDirectory.name);
          },
          child: Text(lang.joinExistingSpace),
        ),
      ],
    );
  }
}
