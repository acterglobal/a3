import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
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
      categoryBuilder.add(categoryList[i]);
    }

    //Save category builder
    final space = await ref.read(spaceProvider(spaceId).future);
    space.setCategories(categoriesFor.name, categoryBuilder);
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
