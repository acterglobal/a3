import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::save_categories');

void saveCategories(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  CategoriesFor categoriesFor,
  List<CategoryModelLocal> categoryList,
) async {
  // Show loading message
  EasyLoading.show(status: L10n.of(context).updatingCategories);
  try {
    //Get category manager
    final categoriesManager = await ref.read(
      categoryManagerProvider(
        (spaceId: spaceId, categoriesFor: categoriesFor),
      ).future,
    );
    final sdk = await ref.watch(sdkProvider.future);
    final displayBuilder = sdk.api.newDisplayBuilder();

    //Get category builder
    final categoriesBuilder = categoriesManager.updateBuilder();

    //Clear category builder data and Add new
    categoriesBuilder.clear();
    for (int i = 0; i < categoryList.length; i++) {
      if (categoryList[i].title != 'Un-categorized') {
        final newCategoryItem = categoriesManager.newCategoryBuilder();
        //ADD TITLE
        newCategoryItem.title(categoryList[i].title);

        //ADD COLOR AND ICON
        displayBuilder.color(categoryList[i].color.value);
        displayBuilder.icon('acter-icon', categoryList[i].icon.name);
        newCategoryItem.display(displayBuilder.build());

        //ADD ENTRIES
        for (int j = 0; j < categoryList[i].entries.length; j++) {
          newCategoryItem.addEntry(categoryList[i].entries[j]);
        }
        categoriesBuilder.add(newCategoryItem.build());
      }
    }

    //Save category builder
    final space = await ref.read(spaceProvider(spaceId).future);
    space.setCategories(categoriesFor.name, categoriesBuilder);

    EasyLoading.dismiss();
    if (context.mounted) {
      Navigator.pop(context);
    }
  } catch (e, s) {
    _log.severe('Failed to save categories', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).updatingCategoriesFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> clearCategories(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) async {
  // Show loading message
  EasyLoading.show(status: L10n.of(context).updatingCategories);
  try {
    final maybeSpace = await ref.watch(maybeSpaceProvider(spaceId).future);
    if (maybeSpace != null) {
      final categoriesManager = await maybeSpace.categories('spaces');

      final newCats = categoriesManager.updateBuilder();
      newCats.clear();
      maybeSpace.setCategories('spaces', newCats);
      if (context.mounted) {
        EasyLoading.dismiss();
        return;
      }
    }
  } catch (e, s) {
    _log.severe('Failed to update categories', e, s);
    if (context.mounted) {
      EasyLoading.dismiss();
      EasyLoading.showError(
        L10n.of(context).updatingCategoriesFailed(e),
        duration: const Duration(seconds: 3),
      );
      return;
    }
  }
}

Future<void> addDummyData(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) async {
  // Show loading message
  EasyLoading.show(status: L10n.of(context).updatingCategories);
  try {
    final maybeSpace = await ref.watch(maybeSpaceProvider(spaceId).future);
    if (maybeSpace != null) {
      final categoriesManager = await maybeSpace.categories('spaces');

      final newCats = categoriesManager.updateBuilder();
      newCats.clear();
      final sdk = await ref.watch(sdkProvider.future);
      final displayBuilder = sdk.api.newDisplayBuilder();

      /// --------(NEW CATEGORY-1)--------
      final newCat1 = categoriesManager.newCategoryBuilder();
      //ADD TITLE
      newCat1.title('Test Cat - 1');

      //ADD COLOR AND ICON
      displayBuilder.color(Colors.red.value);
      displayBuilder.icon('acter-icon', ActerIcon.addressBook.name);
      newCat1.display(displayBuilder.build());

      //ADD ENTRIES
      newCats.add(newCat1.build());

      /// --------(NEW CATEGORY-2)--------
      final newCat2 = categoriesManager.newCategoryBuilder();

      //ADD TITLE
      newCat2.title('Test Cat - 2');

      //ADD COLOR AND ICON
      displayBuilder.color(Colors.blue.value);
      displayBuilder.icon('acter-icon', ActerIcon.appleLogo.name);
      newCat2.display(displayBuilder.build());

      //ADD ENTRIES
      newCats.add(newCat2.build());

      maybeSpace.setCategories('spaces', newCats);
    }
    if (context.mounted) {
      EasyLoading.dismiss();
      return;
    }
  } catch (e, s) {
    _log.severe('Failed to update categories', e, s);
    if (context.mounted) {
      EasyLoading.dismiss();
      EasyLoading.showError(
        L10n.of(context).updatingCategoriesFailed(e),
        duration: const Duration(seconds: 3),
      );
      return;
    }
  }
}
