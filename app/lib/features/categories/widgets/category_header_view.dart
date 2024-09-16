import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CategoryHeaderView extends StatelessWidget {
  final CategoryModelLocal categoryModelLocal;
  final bool isShowDragHandle;

  const CategoryHeaderView({
    super.key,
    required this.categoryModelLocal,
    this.isShowDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCategoryHeader();
  }

  Widget _buildCategoryHeader() {
    return Row(
      children: [
        ActerIconWidget(
          iconSize: 24,
          color: categoryModelLocal.color,
          icon: categoryModelLocal.icon,
        ),
        const SizedBox(width: 6),
        Text(categoryModelLocal.title),
        const Spacer(),
        if (isShowDragHandle) Icon(PhosphorIcons.dotsSixVertical()),
      ],
    );
  }
}
