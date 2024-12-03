import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CategoryHeaderView extends StatelessWidget {
  final CategoryModelLocal categoryModelLocal;
  final Color? headerBackgroundColor;
  final bool isShowDragHandle;
  final Function()? onClickEditCategory;
  final Function()? onClickDeleteCategory;

  const CategoryHeaderView({
    super.key,
    required this.categoryModelLocal,
    this.isShowDragHandle = false,
    this.headerBackgroundColor,
    this.onClickEditCategory,
    this.onClickDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryUtils().isValidCategory(categoryModelLocal)
        ? _buildCategoryHeader(context)
        : _buildUnCategoriesHeader(context);
  }

  Widget _buildCategoryHeader(BuildContext context) {
    final title = categoryModelLocal.title;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: headerBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          if (isShowDragHandle) Icon(PhosphorIcons.dotsSixVertical()),
          ActerIconWidget(
            iconSize: 24,
            color: categoryModelLocal.color,
            icon: categoryModelLocal.icon,
          ),
          const SizedBox(width: 6),
          title != null ? Text(title) : Text(L10n.of(context).uncategorized),
          const Spacer(),
          if (isShowDragHandle) _buildMenuOptions(context),
        ],
      ),
    );
  }

  Widget _buildUnCategoriesHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        L10n.of(context).uncategorized,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).disabledColor),
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    final lang = L10n.of(context);
    return PopupMenuButton(
      icon: Icon(PhosphorIcons.dotsThreeVertical()),
      iconSize: 28,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          onTap: onClickEditCategory.map((cb) => () => cb()),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.pencil()),
              const SizedBox(width: 6),
              Text(lang.editCategory),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onClickDeleteCategory.map((cb) => () => cb()),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.trash()),
              const SizedBox(width: 6),
              Text(lang.deleteCategory),
            ],
          ),
        ),
      ],
    );
  }
}
