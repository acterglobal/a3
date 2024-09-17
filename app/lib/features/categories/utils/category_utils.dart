import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

CategoriesFor getCategoryEnumFromName(String name) {
  return CategoriesFor.values.firstWhere((v) => v.name == name);
}

List<CategoryModelLocal> getCategorisedSubSpacesWithoutEmptyList(
  List<Category> categoryList,
  List<String> subSpaceList,
) {
//CONVERT CATEGORY LIST TO LOCAL CATEGORY LIST
  List<CategoryModelLocal> categoryListLocal =
      getCategorisedSubSpaces(categoryList, subSpaceList);

  List<CategoryModelLocal> categoryListLocalWithoutEmptyEntries = [];
  for (var categoryListLocal in categoryListLocal) {
    if (categoryListLocal.entries.isNotEmpty) {
      categoryListLocalWithoutEmptyEntries.add(categoryListLocal);
    }
  }
  return categoryListLocalWithoutEmptyEntries;
}

List<CategoryModelLocal> getCategorisedSubSpaces(
  List<Category> categoryList,
  List<String> subSpaceList,
) {
//CONVERT CATEGORY LIST TO LOCAL CATEGORY LIST
  List<CategoryModelLocal> categoryListLocal =
      getLocalCategoryList(categoryList);

//GET CATEGORIES SPACE IDs
  List<String> categoriesSpaceIds = [];
  for (var spaceId in subSpaceList) {
    for (var categoryItemLocal in categoryListLocal) {
      if (categoryItemLocal.entries.contains(spaceId)) {
        categoriesSpaceIds.add(spaceId);
      }
    }
  }

//GET UN-CATEGORIES SPACE IDs
  List<String> unCategoriesSpaceIds = subSpaceList;
  for (var spaceId in categoriesSpaceIds) {
    unCategoriesSpaceIds.remove(spaceId);
  }

//ADD UN-CATEGORIES ITEM
  CategoryModelLocal unCategorized = CategoryModelLocal(
    entries: unCategoriesSpaceIds,
    title: 'Un-categorized',
    icon: ActerIcon.list,
    color: Colors.blueGrey,
  );
  categoryListLocal.add(unCategorized);

  return categoryListLocal;
}

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
