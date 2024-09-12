import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
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
  List<Category> categoryList,
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

    //Get category builder
    final categoryBuilder = categoriesManager.updateBuilder();

    //Clear category builder data and Add new
    categoryBuilder.clear();
    for (int i = 0; i < categoryList.length; i++) {
      final Category category = categoryList[i];
      final categoryItemBuilder = category.updateBuilder();
      final newEntries =
          category.entries().map((s) => s.toDartString()).toList();
      categoryItemBuilder.clearEntries();
      for (int j = 0; j < newEntries.length; j++) {
        categoryItemBuilder.addEntry(newEntries[j]);
      }
      final newCategoryItem = categoryItemBuilder.build();
      categoryBuilder.add(newCategoryItem);
    }

    //Save category builder
    final space = await ref.read(spaceProvider(spaceId).future);
    space.setCategories(categoriesFor.name, categoryBuilder);

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
      newCat1.addEntry('!ECGEsoitdTwuBFQlWq:m-1.acter.global');
      newCat1.addEntry('!ETVXYJQaiONyZgsjNE:m-1.acter.global');
      newCats.add(newCat1.build());

      /// --------(NEW CATEGORY-2)--------
      final newCat2 = categoriesManager.newCategoryBuilder();

      //ADD TITLE
      newCat2.title('Test Cat - 2');

      //ADD COLOR AND ICON
      displayBuilder.color(Colors.green.value);
      displayBuilder.icon('acter-icon', ActerIcon.airplay.name);
      newCat2.display(displayBuilder.build());

      //ADD ENTRIES
      newCat2.addEntry('!QttcPDfFpCKjwjDLgg:m-1.acter.global');
      newCats.add(newCat2.build());

      /// --------(NEW CATEGORY-3)--------
      final newCat3 = categoriesManager.newCategoryBuilder();

      //ADD TITLE
      newCat3.title('Test Cat - 3');

      //ADD COLOR AND ICON
      displayBuilder.color(Colors.blue.value);
      displayBuilder.icon('acter-icon', ActerIcon.appleLogo.name);
      newCat3.display(displayBuilder.build());

      //ADD ENTRIES
      newCat3.addEntry('!rvKjUYxJTzOmesLgut:acter.global');
      newCats.add(newCat3.build());

      /// --------(NEW CATEGORY-4)--------
      final newCat4 = categoriesManager.newCategoryBuilder();

      //ADD TITLE
      newCat4.title('Test Cat - 4');

      //ADD COLOR AND ICON
      displayBuilder.color(Colors.pinkAccent.value);
      displayBuilder.icon('acter-icon', ActerIcon.camera.name);
      newCat4.display(displayBuilder.build());

      //ADD ENTRIES
      newCat4.addEntry('!rvKjUYxJTzOmesLgut:acter.global');
      newCats.add(newCat4.build());

      /// --------(NEW CATEGORY-5)--------
      final newCat5 = categoriesManager.newCategoryBuilder();

      //ADD TITLE
      newCat5.title('Test Cat - 5');

      //ADD COLOR AND ICON
      displayBuilder.color(Colors.orange.value);
      displayBuilder.icon('acter-icon', ActerIcon.backpack.name);
      newCat5.display(displayBuilder.build());

      //ADD ENTRIES
      newCat5.addEntry('!rvKjUYxJTzOmesLgut:acter.global');
      newCats.add(newCat5.build());
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
