import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showSectionBg;
  final bool isShowSeeAllButton;
  final VoidCallback? onTapSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTapSeeAll,
    this.showSectionBg = true,
    this.isShowSeeAllButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return sectionHeaderUI(context);
  }

  Widget sectionHeaderUI(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleMediumTextStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor);
    final titleSmallTextStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal);
    return GestureDetector(
      onTap: onTapSeeAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        margin: showSectionBg ? const EdgeInsets.symmetric(vertical: 12) : null,
        decoration:
            showSectionBg
                ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.9),
                      colorScheme.surface.withValues(alpha: 0.3),
                      colorScheme.secondaryContainer.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    stops: const [0.0, 0.5, 1.0],
                    tileMode: TileMode.mirror,
                  ),
                )
                : null,
        child: Row(
          children: [
            Text(
              title,
              style: showSectionBg ? titleMediumTextStyle : titleSmallTextStyle,
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
