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
    if (!bookmarkedSpacesList.isNotEmpty) {
      return SpaceListWidget(
        spaceListProvider: bookmarkedSpacesProvider,
        showSectionHeader: true,
        isShowSeeAllButton: true,
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
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          lang.youAreCurrentlyNotConnectedToAnySpaces,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: lang.create,
                style: textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: lang.or),
              TextSpan(
                text: lang.join,
                style: textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' ',
                style: textTheme.bodyMedium,
              ),
              TextSpan(
                text: lang.spaceShortDescription,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          softWrap: true,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: OutlinedButton.icon(
            key: createNewSpaceKey,
            icon: const Icon(Icons.chevron_right_outlined),
            onPressed: () => context.pushNamed(Routes.createSpace.name),
            label: Text(lang.createNewSpace),
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: ActerPrimaryActionButton(
            key: joinExistingSpaceKey,
            onPressed: () {
              context.pushNamed(Routes.searchPublicDirectory.name);
            },
            child: Text(lang.joinExistingSpace),
          ),
        ),
      ],
    );
  }
}
