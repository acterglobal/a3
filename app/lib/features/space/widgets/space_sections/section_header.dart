import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isShowSeeAllButton;
  final VoidCallback? onTapSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTapSeeAll,
    this.isShowSeeAllButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return sectionHeaderUI(context);
  }

  Widget sectionHeaderUI(BuildContext context) {
    return GestureDetector(
      onTap: onTapSeeAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.9),
              Theme.of(context).colorScheme.surface.withOpacity(0.3),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            stops: const [0.0, 0.5, 1.0],
            tileMode: TileMode.mirror,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).primaryColor),
            ),
            const Spacer(),
            isShowSeeAllButton
                ? ActerInlineTextButton(
                    onPressed: onTapSeeAll,
                    child: Text(L10n.of(context).seeAll),
                  )
                : const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
