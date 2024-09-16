import 'package:file_picker/file_picker.dart';

Future<FilePickerResult?> pickImage({String? dialogTitle}) async {
  return await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    type: FileType.image,
  );
}
