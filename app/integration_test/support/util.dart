import 'dart:io';

import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/config/setup.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'spaces.dart';

extension ActerUtil on ConvenientTest {
  Future<void> navigateTo(List<Key> keys) async {
    for (final key in keys) {
      final nextKey = find.byKey(key);
      await tester.ensureVisible(nextKey);
      await nextKey.should(findsOneWidget, reason: '$nextKey not found');
      await nextKey.tap();
    }
  }

  Future<void> ensureHasBackButton() async {
    await ensureHasWidget<BackButton>();
  }

  Future<void> ensureHasWidget<T>() async {
    await find.byWidgetPredicate((widget) => widget is T).should(
          findsOneWidget,
          reason: '$T was expected but not found',
        );
  }

  Future<void> fillForm(
    Map<Key, String> fields, {
    Key? submitBtnKey,
    String? selectSpaceId,
  }) async {
    for (final entry in fields.entries) {
      final textField = find.byKey(entry.key);
      await tester.ensureVisible(textField);
      await textField.should(findsOneWidget);
      await textField.enterTextWithoutReplace(entry.value);
    }
    if (selectSpaceId != null) {
      await selectSpace(selectSpaceId, SelectSpaceFormField.openKey);
    }
    if (submitBtnKey != null) {
      final submit = find.byKey(submitBtnKey);
      await tester.ensureVisible(submit);
      await submit.should(findsOneWidget);
      await submit.tap();
    }
  }

  Future<void> ensureLabEnabled(LabsFeature feat) async {
    if (!mainProviderContainer.read(isActiveProvider(feat))) {
      // ensure we do actually have access to the main nav.
      await find.byKey(Keys.mainNav).should(findsOneWidget);
      final quickJumpKey = find.byKey(MainNavKeys.quickJump);
      await quickJumpKey.should(findsOneWidget);
      await quickJumpKey.tap();

      final profileKey = find.byKey(QuickJumpKeys.settings);
      await profileKey.should(findsOneWidget);
      await profileKey.tap();

      final labsKey = find.byKey(SettingsMenu.labs);
      await labsKey.should(findsOneWidget);
      await labsKey.tap();

      final confirmKey = find.byKey(Key('labs-${feat.name}'));
      await confirmKey.should(findsOneWidget);
      // let's read again
      if (!mainProviderContainer.read(isActiveProvider(feat))) {
        await confirmKey.tap();
      }

      await tester.pump(const Duration(seconds: 1));

      // ensure we are active
      assert(
        mainProviderContainer.read(isActiveProvider(feat)),
        'Could not activate $feat',
      );
    }
    // either way, go to home.
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final homeKey = find.byKey(MainNavKeys.dashboardHome);
    await homeKey.should(findsOneWidget);
    await homeKey.tap();
  }

  Future<void> trigger(Key key) async {
    final simple = find.byKey(key);
    await simple.should(findsOneWidget);
    await simple.tap();
  }
}

Future<XFile> convertAssetImageToXFile(String assetPath) async {
  // Load the asset as a byte data
  final byteData = await rootBundle.load(assetPath);

  // Create a temporary directory
  Directory tempDir = await Directory.systemTemp.createTemp();

  // Create a new file in the temporary directory
  final fileName = p.basename(assetPath);
  final file = File(p.join(tempDir.path, fileName));

  // Write the asset byte data to the file
  if (!(await file.exists())) {
    await file.create(recursive: true);
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
  }

  // Return the file as an XFile
  return XFile(file.path);
}
