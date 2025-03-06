import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::save_categories');

Future<void> saveCategories(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  CategoriesFor categoriesFor,
  List<CategoryModelLocal> categoryList,
) async {
  final lang = L10n.of(context);
  // Show loading message
  EasyLoading.show(status: lang.updatingCategories);
  try {
    //Get category manager
    final categoriesManager = await ref.read(
      categoryManagerProvider((
        spaceId: spaceId,
        categoriesFor: categoriesFor,
      ),).future,
    );
    final sdk = await ref.watch(sdkProvider.future);
    final displayBuilder = sdk.api.newDisplayBuilder();

    //Get category builder
    final categoriesBuilder = categoriesManager.updateBuilder();

    //Clear category builder data and Add new
    categoriesBuilder.clear();
    for (final category in categoryList) {
      bool isValidCategory = CategoryUtils().isValidCategory(category);
      if (!isValidCategory) continue;
      final title = category.title;
      if (title == null) continue;
      final newCategoryItem = categoriesManager.newCategoryBuilder();
      //ADD TITLE
      newCategoryItem.title(title);

      //ADD COLOR AND ICON
      category.color.map((color) {
        displayBuilder.color(color.toInt());
      });
      category.icon.map((icon) {
        displayBuilder.icon('acter-icon', icon.name);
      });
      newCategoryItem.display(displayBuilder.build());

      //ADD ENTRIES
      for (final entry in category.entries) {
        newCategoryItem.addEntry(entry);
      }
      categoriesBuilder.add(newCategoryItem.build());
    }

    //Save category builder
    final space = await ref.read(spaceProvider(spaceId).future);
    space.setCategories(categoriesFor.name, categoriesBuilder);

    EasyLoading.dismiss();
  } catch (e, s) {
    _log.severe('Failed to save categories', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updatingCategoriesFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}
