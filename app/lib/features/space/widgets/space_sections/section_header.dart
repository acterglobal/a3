import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isShowSeeAllButton;
  final Function()? onTapSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.isShowSeeAllButton = false,
    this.onTapSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return sectionHeaderUI(context);
  }

  Widget sectionHeaderUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          if (isShowSeeAllButton)
            ActerInlineTextButton(
              onPressed: () => onTapSeeAll,
              child: Text(L10n.of(context).seeAll),
            ),
        ],
      ),
    );
  }
}
