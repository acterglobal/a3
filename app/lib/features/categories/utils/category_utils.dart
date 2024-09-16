import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

List<CategoryModelLocal> getLocalCategoryList(List<Category> categoryList) {
  List<CategoryModelLocal> categoryListLocal = [];
  for (var categoryItem in categoryList) {
    final title = categoryItem.title();
    final color = convertColor(
      categoryItem.display()?.color(),
      iconPickerColors[0],
    );
    final icon = ActerIcon.iconForPin(categoryItem.display()?.iconStr());
    final entries =
        categoryItem.entries().map((s) => s.toDartString()).toList();

    CategoryModelLocal categoryModelLocal = CategoryModelLocal(
      title: title,
      color: color,
      icon: icon,
      entries: entries,
    );
    categoryListLocal.add(categoryModelLocal);
  }

  return categoryListLocal;
}
