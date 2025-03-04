import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceListEmptyState extends ConsumerWidget {
  final String searchValue;

  const SpaceListEmptyState({super.key, required this.searchValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(lang.noSpacesFound),
        ActerInlineTextButton(
          onPressed: () {
            context.pushNamed(
              Routes.searchPublicDirectory.name,
              queryParameters: {'query': searchValue},
            );
          },
          child: Text(lang.searchPublicDirectory),
        ),
      ],
    );
  }
}
