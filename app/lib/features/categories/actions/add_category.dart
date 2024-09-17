import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::save_categories');

void addCategory(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  CategoriesFor categoriesFor,
  String categoryTitle,
  Color color,
  ActerIcon icon,
) async {
  // Show loading message
  EasyLoading.show(status: L10n.of(context).addingNewCategory);
  try {
    //GET REQUIRE DATA FROM PROVIDERS
    final categoriesManager = await ref.read(
      categoryManagerProvider(
        (spaceId: spaceId, categoriesFor: categoriesFor),
      ).future,
    );
    final sdk = await ref.watch(sdkProvider.future);
    final displayBuilder = sdk.api.newDisplayBuilder();

    //BUILD NEW CATEGORY
    final newCategory = categoriesManager.newCategoryBuilder();
    newCategory.title(categoryTitle);
    displayBuilder.color(color.value);
    displayBuilder.icon('acter-icon', icon.name);
    newCategory.display(displayBuilder.build());

    //SAVE NEW CATEGORY in CATEGORIES BUILDER
    final categoriesUpdateBuilder = categoriesManager.updateBuilder();
    categoriesUpdateBuilder.add(newCategory.build());

    //SAVE UPDATED CATEGORIES BUILDER IN SPACE
    final space = await ref.read(spaceProvider(spaceId).future);
    space.setCategories(categoriesFor.name, categoriesUpdateBuilder);

    EasyLoading.dismiss();
    if (context.mounted) {
      Navigator.pop(context);
    }
  } catch (e, s) {
    _log.severe('Failed to add category', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).addingNewCategoriesFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}
