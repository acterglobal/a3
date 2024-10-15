import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
    final bookmarkedSpaces = ref.watch(bookmarkedSpacesProvider);
    final spaces = ref.watch(spacesProvider);
    final lang = L10n.of(context);
    if (bookmarkedSpaces.isNotEmpty) {
      return _RenderSpacesSection(
        spaces: bookmarkedSpaces,
        limit: bookmarkedSpaces.length,
        showAll: true,
        showAllCounter: spaces.length,
        title: Text(
          lang.bookmarkedSpaces,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
    }

    // fallback
    if (spaces.isEmpty) {
      return const _NoSpacesWidget();
    }

    final count = limit == null ? spaces.length : min(spaces.length, limit!);
    return _RenderSpacesSection(
      spaces: spaces,
      limit: count,
      showAll: count != spaces.length,
      showActions: count == spaces.length,
      showAllCounter: spaces.length,
      title: InkWell(
        key: DashboardKeys.widgetMySpacesHeader,
        onTap: () => context.pushNamed(Routes.spaces.name),
        child: Text(
          lang.mySpaces,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}

class _RenderSpacesSection extends ConsumerWidget {
  final int limit;
  final List<Space> spaces;
  final Widget title;
  final bool showAll;
  final bool showActions;
  final int showAllCounter;

  const _RenderSpacesSection({
    required this.spaces,
    required this.limit,
    required this.title,
    this.showActions = false,
    this.showAll = false,
    this.showAllCounter = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            title,
            const Spacer(),
            if (showAll)
              ActerInlineTextButton(
                onPressed: () => context.pushNamed(Routes.spaces.name),
                child: Text(lang.seeAll),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          itemCount: limit,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => RoomCard(
            roomId: spaces[index].getRoomIdStr(),
            margin: const EdgeInsets.only(bottom: 14),
          ),
        ),
        if (showActions)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () => context.pushNamed(Routes.createSpace.name),
                  child: Text(lang.createSpace),
                ),
                const SizedBox(height: 10),
                ActerPrimaryActionButton(
                  onPressed: () {
                    context.pushNamed(Routes.searchPublicDirectory.name);
                  },
                  child: Text(lang.joinSpace),
                ),
              ],
            ),
          ),
      ],
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
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          lang.youAreCurrentlyNotConnectedToAnySpaces,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: lang.create,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(text: lang.or),
              TextSpan(
                text: lang.join,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: ' ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextSpan(
                text: lang.spaceShortDescription,
                style: Theme.of(context).textTheme.bodyMedium,
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
