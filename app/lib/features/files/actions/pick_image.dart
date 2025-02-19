import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

Future<FilePickerResult?> pickImage({
  required L10n lang,
  String? dialogTitle,
}) async {
  if (Platform.isAndroid) {
    // On Android 8-10 we must be sure to query for the `storage` permission
    // before engaging an image-based file-picker
    // see https://github.com/miguelpruivo/flutter_file_picker/issues/1461
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt <= 29) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        EasyLoading.showToast(lang.missingStoragePermissions);
        return null;
      }
    }
  }
  return await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    type: FileType.image,
  );
}
