import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class CategoryUtils {
  ///CREATE SINGLETON CLASS OBJECT
  static final CategoryUtils _singleton = CategoryUtils._internal();

  factory CategoryUtils() {
    return _singleton;
  }

  CategoryUtils._internal();

  ///CATEGORY ENUM ITEM FROM NAME
  CategoriesFor getCategoryEnumFromName(String name) {
    return CategoriesFor.values.firstWhere((v) => v.name == name);
  }

  ///CHECK FOR UN-CATEGORIZED TYPE
  bool isValidCategory(CategoryModelLocal category) {
    return category.color != null && category.icon != null;
  }

  ///GET CATEGORIES LOCAL LIST BASED ON ITEM ENTRIES
  List<CategoryModelLocal> getCategorisedList(
    List<Category> categoryList,
    List<String> entries,
  ) {
    //CONVERT CATEGORY LIST TO LOCAL CATEGORY LIST
    List<CategoryModelLocal> categoryListLocal =
        convertToLocalCategoryList(categoryList);

    //GET CATEGORIES ENTRIES
    List<String> categoriesEntriesList = [];
    for (var entryItem in entries) {
      for (var categoryItemLocal in categoryListLocal) {
        if (categoryItemLocal.entries.contains(entryItem)) {
          categoriesEntriesList.add(entryItem);
        }
      }
    }

    //GET UN-CATEGORIES ENTRIES
    List<String> unCategoriesEntriesList = entries;
    for (var entryItem in categoriesEntriesList) {
      unCategoriesEntriesList.remove(entryItem);
    }

    //ADD UN-CATEGORIES ITEM to LAST POSITION
    CategoryModelLocal unCategorized = CategoryModelLocal(
      entries: unCategoriesEntriesList,
      isUncategorized: true,
    );
    categoryListLocal.add(unCategorized);

    //RETURN FINAL LOCAL CATEGORY LIST
    return categoryListLocal;
  }

  ///GET CATEGORY LIST TO LOCAL CATEGORY LIST
  List<CategoryModelLocal> convertToLocalCategoryList(
    List<Category> categoryList,
  ) {
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
}
