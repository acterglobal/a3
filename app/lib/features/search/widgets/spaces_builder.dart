import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter/features/search/providers/spaces.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SpacesBuilder extends ConsumerWidget {
  const SpacesBuilder({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundSpaces = ref.watch(spacesFoundProvider);
    return foundSpaces.when(
      loading: () => renderLoading(context),
      error: (e, st) => inBox(
        context,
        Text(L10n.of(context).error(e)),
      ),
      data: (data) {
        if (data.isEmpty) {
          return renderEmpty(context, ref);
        }
        return renderItems(context, ref, data);
      },
    );
  }

  Widget renderLoading(BuildContext context) {
    return inBox(
      context,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            padding: const EdgeInsets.all(10),
            child: const Column(
              children: [
                Skeletonizer(child: Icon(Icons.abc)),
                SizedBox(height: 3),
                Skeletonizer(child: Text('space name')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget renderItems(
    BuildContext context,
    WidgetRef ref,
    List<SpaceDetails> items,
  ) {
    return inBox(
      context,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .map(
                (e) => InkWell(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        e.icon,
                        const SizedBox(height: 3),
                        Text(e.name),
                      ],
                    ),
                  ),
                  onTap: () {
                    if (context.canPop()) context.pop();
                    goToSpace(context, e.navigationTargetId);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget renderEmpty(BuildContext context, WidgetRef ref) {
    return inBox(
      context,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            L10n.of(context).noSpacesFound,
          ),
          ActerInlineTextButton(
            onPressed: () {
              final query = ref.read(searchValueProvider);
              context.pushNamed(
                Routes.searchPublicDirectory.name,
                queryParameters: {'query': query},
              );
            },
            child: Text(L10n.of(context).searchPublicDirectory),
          ),
        ],
      ),
    );
  }

  Widget inBox(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Text(L10n.of(context).spaces),
          const SizedBox(height: 15),
          child,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
