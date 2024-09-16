import 'package:acter/features/files/actions/pick_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<FilePickerResult?> pickAvatar({required BuildContext context}) =>
    pickImage(
      lang: L10n.of(context),
      dialogTitle: L10n.of(context).uploadAvatar,
    );
