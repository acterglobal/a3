import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CategoryHeaderView extends StatelessWidget {
  final CategoryModelLocal categoryModelLocal;
  final Color? headerBackgroundColor;
  final bool isShowDragHandle;
  final Function()? onClickDeleteCategory;

  const CategoryHeaderView({
    super.key,
    required this.categoryModelLocal,
    this.isShowDragHandle = false,
    this.headerBackgroundColor,
    this.onClickDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return (categoryModelLocal.title == 'Un-categorized')
        ? _buildUnCategoriesHeader(context)
        : _buildCategoryHeader(context);
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Text(categoryModelLocal.title),
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
        categoryModelLocal.title,
        style: Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(color: Theme.of(context).disabledColor),
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(PhosphorIcons.dotsThreeVertical()),
      iconSize: 28,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          onTap: () {},
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.pencil()),
              const SizedBox(width: 6),
              Text(L10n.of(context).editCategory),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => onClickDeleteCategory!=null?onClickDeleteCategory!():null,
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.trash()),
              const SizedBox(width: 6),
              Text(L10n.of(context).deleteCategory),
            ],
          ),
        ),
      ],
    );
  }
}
